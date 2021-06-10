# QuickMag.jl
This is a Julia implementation of QuickMag. QuickMag is a method for determining the approximate magnitude of a given CPU/GPU on all Gridcoin whitelisted projects. The move to Julia allows for more efficient data processing and easier parallelization of the code. Additionally, the process of adding or removing projects from the Gridcoin whitelist has been streamlined and now just requires adding/removing lines from the WhiteList.csv file.

The program will open a Julia terminal, download additional dependencies, and then start building the required hardware databases from publicly available BOINC project data. Once the database has been built, you can follow the instructions on screen to estimate the performance of a CPU, estimate the performance of a GPU, or print surveys of what CPU/GPU models are most commonly being used. 

The code here will eventually replace the backend code for http://quickmag.ml/

**Requires:**

    *Julia (version 1.5 or later): https://julialang.org/downloads/ 
    *5GB RAM
    *600MB disk space


**Steps for starting QuickMag: Windows**

    Double click on Start_Win.bat to start QuickMag.jl

**Steps for starting QuickMag: Linux**

    Run Start_Bash.sh from the terminal to start QuickMag.jl
or

    Directly run ./QuickMag.jl (will default to single threaded mode)

**Using QuickMag**

After starting the program, just follow the instructions in the terminal. Updating the database takes a long time as this requires downloading 2-3 GB of data from various whitelisted BOINC projects. Please do not update your database more than once every 24 hours, it wastes the bandwidth of the projects.

Running the CPU survey and GPU survey options will provide lots of examples if you are unsure of the proper formatting for a CPUid/GPUid string. Searches are not case sensitive and will include all matching CPU models. For example searching for 'i7-6700' will combine results for the 'i7-6700 ' and 'i7-6700K'.

All performance results are reported in units of magnitude:

    1 Mag = 0.25 GRC/Day
    
Also note that Einstein@home is not listed in WhiteList.csv. The project does not publish the host data so we cannot estimate performance for this project.


    
