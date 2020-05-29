
framework:
	bazel build --config=ios_arm64 --cxxopt='-std=c++14' mediapipe/handtracker:HandTracker
	cd bazel-bin/mediapipe/handtracker/ &&\
	rm -rf HandTracker.framework &&\
	unzip HandTracker.zip &&\
	cd HandTracker.framework &&\
	ar -dv HandTracker  NSError+util_status_f64093ca561b3913726e4e3728906dd8.o