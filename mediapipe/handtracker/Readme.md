# HandTracker framework sources
The contents of this folder are used to build HandTracker.framework. This is what is being used to track the hand.

In case of changes being done, this can be rebuild by moving this folder inside a folder with all the mediapipe files and executing `bazel build --config=ios_arm64 --cxxopt='-std=c++14' --define 3D=true mediapipe/handtracker:HandTracker`

Then the builded file can be found inside `bazel-bin/mediapipe/handtracker` by unzipping HandTracker.zip.

The same process can be done should another framework be created. Then add this to the `Link Binary With Library` section of `Build Phase` in the Xcode project. Also add `#include <MyFramework/MyFramework.h>` to the Bridging header of the project to use the framework in Swift code.
