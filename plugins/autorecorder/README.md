About
------
Plugin that controls demo recording process, aiming to capture only useful footage for generic purpose.

Original plugin by [shqke](https://github.com/shqke). Modified by [caxanga334](https://github.com/caxanga334) to allow the plugin to be used on any game with SourceTV Manager support.

Convars
------
- `sm_autorecord_enable` - Enable autorecording features, default: `"1"`
- `sm_autorecord_minplayers` - Minimum amount of players required to start recording, default: `"1"`
- `sm_autorecord_minplayersdelay` - Keep on recording for this long after key player has left (avoids creating a new file on player join), default: `"30"`
- `sm_autorecord_ignorebots` - Don't count bots in when counting players, default: `"1"`
- `sm_autorecord_roundsplit` - Restart demo on `round_start` event rather than on a map change, default: `"1"`
- `sm_autorecord_sizesplit` - Restart demo when reached file size, in megabytes (MB), `0` - disables, default: `"0"`
- `sm_autorecord_lengthsplit` - Restart recording if demo is too long, in minutes, `0` - disables, default: `"0"`
- `sm_autorecord_allowoverwrites` - If disabled, append a `.<counter>` before extension if file exists (up to 10000), default: `"0"`
- `sm_autorecord_pathfmt` - Custom path format (relative to mod folder) for recordings, default: `""`
- `sm_server_uid` - Unique server string identifier, default: `""`

Admin Commands
------
- `sm_record [path]` - Start recording to file
  - `path` - optional file path, `sm_autorecord_pathfmt` convar value otherwise or fall back to default format
- `sm_stoprecord` - Stop recording
- `sm_recordstatus` - View recording details

Format Specifiers
------
- `%s` - unix timestamp of when recording has started
- `%q` - randomly generated number in range `[0-99999]`
- `%f` - game folder (e.g. `left4dead2`)
- `%l` - level name without extension (e.g. `c8m1_apartment`)
- `%i` - unique id (from convar `sm_server_uid`)
- `%P` - server game port (from convar `hostport`)
- `%L` - game mode (from convar `mp_gamemode`) (Only for Left 4 Dead/2)
- `%%` - a `%` sign

Also supports single character time format specifiers from https://www.cplusplus.com/reference/ctime/strftime/

Default format is `auto-%Y%m%d-%H%M%S-%l-%q` which expands into `auto-20200101-234820-c8m1_apartment-4321.dem`.

Note
------
Plugin would attempt to create subdirectories with a file mode `0775`, allowing to read, write and execute by user and group, read and write by others.

On Linux consider using [umask](https://man7.org/linux/man-pages/man1/umask.1p.html) in your shell script if you need to override file mode creation mask (default is 022).

Requirements
------
- [SourceTV Manager](https://github.com/peace-maker/sourcetvmanager)

Supported Games
------
- Any game supported by SourceTV Manager.
