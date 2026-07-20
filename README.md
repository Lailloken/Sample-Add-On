## info.json: important entries
- `name`: there will be an importer/downloader that simply downloads a ZIP via a repo URL, the extracted folder will be renamed to this value (which is also the display name in the "add-ons" section of the settings menu)

- `className`: required for instantiating the class, as well as `#Including` the add-on's main `.ahk` file

- `games`: simple array, specifies which game(s) the add-on may be used in

- `repo` + `version`: the importer/downloader will also have update functionality

This list is non-exclusive
<br>
<br>

## How to:
- requires the dev-branch (until the next main release after v1.63.9)

- create an `add-ons` folder in your `Exile UI` folder

- create a `loader` or `loader 2` file (no extension) in this folder, depending on which game you want to use it for (the tool will generate these in the future, once the importer is set up)

  - these files are simply an `#Included` file that are used to `#Include` the main `.ahk` file of an add-on
 
  - each add-on requires a line like this: `#Include *i add-ons\Sample add-on\SampleAddon.ahk`
 
- download this sample add-on and put the files into `add-ons\Sample add-on\`

- restart the tool, open the "add-ons" section and click "enable"

  - this section is normally hidden, but the presence of the `add-ons` folder unhides it

- the section should now list the sample add-on:

  ![img](https://github.com/user-attachments/assets/152cd818-9e52-4d7e-8f56-1a34bf9508da)

  - only the cogwheel and ? buttons are currently fully functional
 
  - disabling the section doesn't technically disable add-ons as of now: to prevent loading add-ons, they have to be removed from the tool folder
