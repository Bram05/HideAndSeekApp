# Big Brother
## Introduction
This app is based on the hide and seek game used in the series [Jetlag](https://nebula.tv/jetlag), built using [Flutter](https://flutter.dev/) and C++.
It helps the seekers keep track of the potential search space by calculating this area based on the questions asked, similar to the graphics in the show.

![Screenshot of choosing the region](/images/choose.png)
![Screenshot of the Netherlands on the app](/images/screenshot1.png)
![Screenshot of the Netherlands after some questions](/images/screenshot2.png)
![Screenshot of Germany](/images/Germany.png)

## Installation
The current setup is only meant to be run with [NixOS](https://nixos.org/). It should also work with basic Nix but that is not tested.
On that distribution first clone this repository and then run nix-shell in this directory to create the development shell.
You then first need to compile th C++ code by going into maths/build (create this first) and running `cmake ..` optionally specifying `-DCMAKE_BUILD_TYPE=...` for the build type
Then you can run `make` to compile (or run 'make.sh' from the main directory). Note: this compilation is only required for builds for linux, not for Android which does its own build.
You should then be able to build and run the program by running `flutter run` in this shell.
To run it on a mobile device, first connect it to your computer, for example by following [these instructions](https://developer.android.com/tools/adb).
Now run `flutter run` optionally specifying `-d DEVICE_NAME`, where DEVICE_NAME can be gotten from `flutter devices`.

## Usage
On first installation there will be no regions to play in. Follow the instructions in [Adding your own regions](#Adding your own regions) to add your first region.
After doing this, click on the region you want to play in and you will be brought to the country map.
In the top you can save/load the current area and ask questions.
Every question can only be asked once and will first require you to send the question to the hiders, as in the original game.
After clicking the corresponding button in the top bar, you can input the answer and the map will update to show the new area.
When saving/loading, there appears to be one bug on Android. Saving to a file will overwrite the contents, but not delete anything if the original content was longer.
To prevent this: only save to new files. This does not appear to be an issue on Linux.
To load a previous save: go to any region and load the save. It is not needed for this region to be the same as the on in the save (I know: this button should be on the home page).
For detailed instructions on every question: view the show.

### Miscellaneous map things
To showcase some of the interesting quirks of the maps, there is also a button on the home screen to play around on the map.
Clicking this brings you to the map with currently two modes.
In the first one 'Circles' you can click/hover anywhere on the screen to draw a circle centered at that point.
Pressing u/d increase/decreases the radius of this circle, or pressing and holding/double pressing and holding on mobile.
It is interesting to see how these circles get distorted near the poles.
Note however that the program cannot properly show circles the include a pole.

In the second mode 'Drawing' you can draw polygons on the map.
Click on some points to draw a polygon through these points and see how to the lines of shortest distance get distorted on the map.
A long presses closes the shape and allows you to begin a new one.
Minor remark: when in the proces of drawing the final line from your current point back to the beginning is not rendered properly.
This is just a straight line the map. Closing the shape does make this line correct.

Press 'Nothing' to go back to the normal map.

### Adding your own regions
These can be downloaded by pressing 'add your own' and then giving the name. This name must be same as the own in OpenStreetMap (see [How it works][#How it works]) from either tag 'name' or 'name_int'.
These can be found at https://openstreetmap.org.
This region must currently have administrative level 2, 3 or 4 (admin_level in OpenStreetMap).
In order for the subarea question to work, this region must contains its subareas (province, cities, etc.) as member relation, with tag subarea.
To verify this scroll to the bottom of the site.
In certain cases it can happen that the relation in OpenStreetMap specifiying the wanted border of the region is not the same as the one providing the subareas.
For instance in the Netherlands the region 'Netherlands' also contains overseas territories that are unwanted in this game, 'European Netherlands' does contain the right area, however.
For the provinces that does not work and one does need 'Netherlands'.
For this scenario press the button 'Name for border is different' and specify the name providing the border there, in this case 'European Netherlands'

Now click 'Add region' to download it, this may take some time.

## How it works
Here we outline generally how the different steps are implemented:
1. Map data
All map data is gathered from [OpenStreetMap](https://www.openstreetmap.org/about).
This includes the map tiles themselves, the borders of regions and proximity data such as the museums around you.
See https://www.openstreetmap.org/copyright for more information on the license this data comes with.
2. Calculations
All calculations in the program are done properly on the spherical surface of the earth (we assume the earth to be perfecly spherical) to provide accurate boundaries.
These are done using vectors in three-dimensional space.
The calculations are done using high precision arithemetic from [MPFR](https://www.mpfr.org/) used in C++, to allow for very precise circles (circles with radius of a single meter work).
For more information on how this information is stored and used see the file maths/src/Shape.h that contains documentation on the most important class 'Shape'.
Every line segment in a shape can be either a straight line (i.e. great circle on earth's surface, the intersection of a plane through the origin with the surface) or part of a circle.
Conviently, however, a circle on earth's surface (i.e. all points of a certain distance along the surface from the center) is exactly the intersection of the plane with the surface.
Every line is therefore given by a plane, a begin and end.
It is, however still necessary to store the direction in which to move from begin to end (for usage in some function we require the angle between begin and end to be at most 180 degrees, but still you can either go clockwise or counter-clockwise).
This direction is elegantly stored in the planes' normal vector. This vector is normalized for convenience but mathemetically there are still two possibilities.
Negating the normal (keeping the same plane) reverses the direction of the line.
This allows for easily finding whether a vector lies on the line segment or not, see Vec3LiesBetween in maths/src/Shape.cpp for the implementation.

3. Intersections
All shapes consist of segments, which are curves defining the boundary oriented in such a way that 'locally' the 'inside' of the shape is 'to the left' (positively oriented).
As an example consider an annulus in two-dimensional space.
The outer segment is then oriented counter-clockwise and the inner is oriented clockwise.
Using these we calculate the intersection as follows: first intersect all segment by intersecting everly line segment of the first shape with every other of the second.
Then choose any intersection and find which shapes moves the most to the left.
Follow this one until you reach the next intersections and repeat this until you are back at the beginning.
This is a segment in the final shape.
Then choose another intersection and repeat until there no more left.
Special care must be taken of segments that do not intersect.
