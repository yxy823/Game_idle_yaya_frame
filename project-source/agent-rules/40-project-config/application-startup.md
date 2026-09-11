# Application Startup

Treat application startup as a production API and test it without mutating production main scene for test convenience.

## Startup

- **[REVIEW]** Changing `application/run/main_scene` is an application startup behavior change.
- **[MUST]** Do not temporarily modify production main scene setting to run tests, screenshots, or fixtures.
- **[PREFER]** Main Scene owns bootstrap/composition appropriate to application startup, not an arbitrary global logic dump.
- **[MUST]** Scenes/modules do not assume `/root/Main/...` as a cross-module dependency contract.
- **[REVIEW]** A custom `main_loop_type` is an architecture-level runtime change and requires target-version validation.
- **[MUST]** When `application/config/use_custom_user_dir` is `false`, changing `application/config/name` changes the default `user://` directory. Treat existing saves, settings, progression, and other user data as a persistence migration and validate compatibility or an explicit migration path.
- **[MUST]** Do not enable `use_custom_user_dir` automatically to avoid that migration; preserve and validate the project's existing user-data namespace contract.
