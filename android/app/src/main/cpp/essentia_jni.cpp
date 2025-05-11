#include <jni.h>
#include "essentia/algorithmfactory.h"
#include "essentia/essentiamath.h"
#include <vector>

using namespace essentia;

extern "C" {

    // Function to get the Essentia version
    JNIEXPORT jstring JNICALL
    Java_com_example_shirr_MainActivity_getEssentiaVersion(JNIEnv* env, jobject /* this */) {
        std::string version = essentia::version;
        return env->NewStringUTF(version.c_str());
    }

    // Function for Beat Detection
    JNIEXPORT jfloatArray JNICALL
    Java_com_example_shirr_MainActivity_detectBeats(JNIEnv* env, jobject /* this */, jfloatArray audioBuffer, jint sampleRate) {
        // Convert the Java float array to C++ vector
        jsize bufferSize = env->GetArrayLength(audioBuffer);
        jfloat* audioData = env->GetFloatArrayElements(audioBuffer, nullptr);
        std::vector<float> audioVec(audioData, audioData + bufferSize);

        // Create the algorithm for beat tracking
        // BeatTrackerMulti beatTracker;
        std::vector<float> beats;
        
        // Process audio buffer
        // beatTracker.compute(audioVec, sampleRate, beats);

        // Convert the C++ vector back to a Java float array
        jfloatArray result = env->NewFloatArray(beats.size());
        // env->SetFloatArrayRegion(result, 0, beats.size(), beats.data());

        // // Release resources
        // env->ReleaseFloatArrayElements(audioBuffer, audioData, JNI_ABORT);

        return result;
    }

    // Function for Onset Detection
    JNIEXPORT jfloatArray JNICALL
    Java_com_example_shirr_MainActivity_detectOnsets(JNIEnv* env, jobject /* this */, jfloatArray audioBuffer, jint sampleRate) {
        // Convert the Java float array to C++ vector
        jsize bufferSize = env->GetArrayLength(audioBuffer);
        jfloat* audioData = env->GetFloatArrayElements(audioBuffer, nullptr);
        std::vector<float> audioVec(audioData, audioData + bufferSize);

        // Create the algorithm for onset detection
        // OnsetDetection onsetDetection("energy");
        std::vector<float> onsets;

        // Process audio buffer
        // onsetDetection.compute(audioVec, sampleRate, onsets);

        // Convert the C++ vector back to a Java float array
        jfloatArray result = env->NewFloatArray(onsets.size());
        // env->SetFloatArrayRegion(result, 0, onsets.size(), onsets.data());

        // Release resources
        env->ReleaseFloatArrayElements(audioBuffer, audioData, JNI_ABORT);

        return result;
    }

    // Function for Pitch Detection
    JNIEXPORT jfloatArray JNICALL
    Java_com_example_shirr_MainActivity_detectPitch(JNIEnv* env, jobject /* this */, jfloatArray audioBuffer, jint sampleRate) {
        // Convert the Java float array to C++ vector
        jsize bufferSize = env->GetArrayLength(audioBuffer);
        jfloat* audioData = env->GetFloatArrayElements(audioBuffer, nullptr);
        std::vector<float> audioVec(audioData, audioData + bufferSize);

        // Create the algorithm for pitch detection
        // PitchYin pitchYin;
        std::vector<float> pitches;

        // Process audio buffer
        // pitchYin.compute(audioVec, sampleRate, pitches);

        // Convert the C++ vector back to a Java float array
        jfloatArray result = env->NewFloatArray(pitches.size());
        env->SetFloatArrayRegion(result, 0, pitches.size(), pitches.data());

        // Release resources
        env->ReleaseFloatArrayElements(audioBuffer, audioData, JNI_ABORT);

        return result;
    }
}
