# AGENTS.md for simple-picture-load project
# This project is to learn how to create an Apple Swift app that is defined in AGENTS.md
# that can load a picture from the camera app or the picture roll.

# Code and liberaries
* Use Apple Swift
* Add directory xcuserdata to the .gitignore file.

# Picture selection specifications
* The user can load a photo from the camera app or the picture roll.
* The picture source selection buttons should be on a view (picture source view) that is can be hidden and follows the following rules:
  * The picture source view is displayed when the phone is shanken (or flicked) around the X axis in the -Z directon and the Y value goes less than 45 degrees.
  * The picture source view is hidden when the phone is shaken (or flicked) around the X axis in the +Z direction and the Y value goes less than 50 degrees.
  * When displayed the picture source view will be maintained until commanded otherwise or a picture is loaded.
  * When a picture is loaded the picture source view will be hide upon loading.
  * At app startup or app restore if no picture is loaded the picture source view will be displayed.
  * At app startup or app restore if a picture is loaded the picture source view will not be displayed.

# Target platforms
* Apple iPhones and iPads
