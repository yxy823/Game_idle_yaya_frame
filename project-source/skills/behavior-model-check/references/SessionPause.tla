---------------------------- MODULE SessionPause ----------------------------
(* 例子：多条件自动暂停。拖动、详情等几个暂停原因各自独立，全部结束才恢复；失败或结束后不再运行。
   active 是环境里真实成立的暂停条件，mask / cnt 是实现保存的状态。
   Mutation 切换受控错误注入：single_flag 结束任一条件就清空全部暂停，
   counter 按次数计数（重复设置会被重复计数），revive 暂停全部结束时把失败的片段改回运行。 *)
EXTENDS Integers

CONSTANT Mutation   \* "none" | "single_flag" | "counter" | "revive"

Reasons == {"drag", "details", "unpack", "reserve"}
MaxClock == 2
MaxCnt == 3

VARIABLES phase, active, mask, cnt, clock
vars == <<phase, active, mask, cnt, clock>>

Init ==
    /\ phase = "running"
    /\ active = [r \in Reasons |-> FALSE]
    /\ mask = {}
    /\ cnt = 0
    /\ clock = 0

\* 实现判断能否推进：正确实现用位掩码；counter 变体用计数，重复设置会被重复计数。
CanAdvance ==
    /\ phase = "running"
    /\ IF Mutation = "counter" THEN cnt = 0 ELSE mask = {}

\* set_pause_condition(reason, on)：同一条件可以被重复设置为同一个值。
SetCond(r, on) ==
    /\ active' = [active EXCEPT ![r] = on]
    /\ mask' = IF on THEN mask \cup {r}
               ELSE IF Mutation = "single_flag" THEN {} ELSE mask \ {r}
    /\ cnt' = IF on THEN cnt + 1 ELSE IF cnt > 0 THEN cnt - 1 ELSE 0
    /\ phase' = IF Mutation = "revive" /\ ~on /\ mask' = {} THEN "running" ELSE phase
    /\ clock' = clock

\* get_time_delta：可以推进时返回本帧时间，否则返回 0。
Tick ==
    /\ clock < MaxClock
    /\ clock' = IF CanAdvance THEN clock + 1 ELSE clock
    /\ UNCHANGED <<phase, active, mask, cnt>>

Fail ==
    /\ phase = "running"
    /\ phase' = "failed"
    /\ UNCHANGED <<active, mask, cnt, clock>>

Finish ==
    /\ phase = "running"
    /\ phase' = "ended"
    /\ UNCHANGED <<active, mask, cnt, clock>>

Next ==
    \/ \E r \in Reasons, on \in BOOLEAN : SetCond(r, on)
    \/ Tick
    \/ Fail
    \/ Finish

Spec == Init /\ [][Next]_vars

StateBound == cnt <= MaxCnt

-----------------------------------------------------------------------------
\* 性质（规则 ID 只在本试点内使用）

AnyActive == \E r \in Reasons : active[r]

\* F003-AC01：多个条件同时成立时，结束其中一个不会恢复；全部结束才恢复。
PauseMatchesConditions ==
    CanAdvance <=> (phase = "running" /\ ~AnyActive)

\* F003-AC02：暂停期间时间不推进。
PausedNoTime == [][AnyActive => clock' = clock]_vars

\* F003-AC03：失败或结束后不会因关闭详情或结束拖动而重新开始。
TerminalPermanent == [][phase # "running" => phase' = phase]_vars
TerminalNoTime == [][phase # "running" => clock' = clock]_vars

\* 业务见证：期望被违反，证明模型没有把“时间推进”限制掉。
WitnessTimeAdvances == clock < MaxClock
=============================================================================
