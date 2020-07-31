# ECE 385 Final Project: Lurking in the Dark on the NIOS II by Sahil Patel and Zach Deardorff
<img src="https://github.com/sahilshahpatel/ece-385-final-project/blob/master/titlescreen.png" alt="Lurking in the Dark title screen" width="100%">

This project was created for the University of Illinois' ECE 385 class (Digital Systems Laboratory). Our task was to create a project using what we learned throughout the semester about FPGA design to create anything we thought could prove our knowledge. Before beginning work on this project, we submitted a proposal to our TA who approved it as difficult enough to qualify for a final project.

We then began developing Lurking in the Dark for the NIOS II. Lurking in the Dark is a mini-game of sorts made by Asher Aryam for a game jam. The original game can be found [here](https://asheraryam.itch.io/lurking-in-the-dark). Our challenge was to develop hardware on the FPGA to interface with the NIOS II software and recreate this game from scratch. We approached this by creating all of the game logic in software while using the hardware to accelerate the graphics which allowed for higher framerates.

### To run the project on a compatible board follow these steps:
1. Download the .sof and .elf files from this repository (in the main folder and in software/final-project)
2. Open Quartus -> Programmer
3. Select "Add File" and choose the .sof
4. Program your board
5. Open Tools -> Software Build Tools for Eclipse
6. Open Run Configurations and check the box to allow you to browse for an ELF file
7. Select the .elf file you downloaded in step 1 and click run

### To set up the full Quartus project follow these steps:
1. Clone the repository to your own computer
2. Open the QPF file in Quartus.
3. Open Tools -> Platform Designer and generate the HDL
4. Add all .sv and .qip files (nios_system.qip will be inside /nios_system/synthesis)
5. Set the top level file to top_level.sv
6. Go to Assignments -> Device and set the device appropriately
7. Compile the project
8. Open eclipse and import all projects from within the base folder
9. Generate the BSP
10. Build all
11. Set up the Run Configurations
12. Run the program!

### A note to current ECE 385 students
Professor Cheng gave us permission to make this repository public, but there are definitely conditions about your use of this work. ECE 385 policy (at the time of writing this) allows you to use work you find online *with credit given*. However, this work is then not counted toward your final difficulty rating. Because of our approach to making a game on the NIOS II, our work is easily re-usable for other games with only software modifications necessary. For this reason, we recommend that you look at this repository only for inspiration. We are not responsible for any accusations of plagiarism leveled at any student who attempts to copy or use our code.
