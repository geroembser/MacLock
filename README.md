# MacLock :lock:
_(still open for name suggestions…)_

Simply connect your MacBook to the power :electric_plug:, "lock" it in your StatusBar :closed_lock_with_key: using _MacLock_, and an alarm :rotating_light: will sound loudly as soon as your MacBook is disconnected from the power.

_Note:_ This is still beta and has some known issues (see [To Do](#to-do-pencil) as well).

## Getting Started
Download MacLock [here](https://github.com/geroembser/MacLock/releases/download/v1.0/MacLock.app.zip), add it to your `/Applications` directory and launch it.


Or clone and build it yourself!


## :warning: No Warranty! :warning:
**No warranty! There are known security issues. If someone wants to steal your Mac, this app won't stop them. However, a warning signal may help to draw attention to what is happening.**

## To Do :pencil:
- [ ] `launchd` helper for improved Authorization flow
- [ ] Write kernel extension which allows playing alarm only through internal speakers (bypass the headphone jack-control which seems to be deeply integrated into the driver)
- [ ] For all the "Terminal-Guys": lock via short terminal command!
- [ ] Mute other processes while playing alarms (like iTunes)
- [ ] Add smartphone notification mechanism
- [ ] Talk to the thieves from your smartphone (e.g. using FaceTime Audio for iOS?!)
- [ ] New alarm sounds
- [ ] Add recognizable icon
- [ ] add more options for customization in Status Bar

_Sounds interesting?_

:arrow_down: **Contribute!**

## Contributing
Contribution is welcome at any time… Just submit a Pull Request...

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments :clap:
- Current alarm sound is "in store anti theft alarm.wav" of "soundslikewillem" released under CC BY-NC 3.0 (https://freesound.org/s/377156/)
- StatusBarItem and AppIcon used modified version of [Unlock by Delta from the Noun Project](https://thenounproject.com/browse/?i=1459045)
