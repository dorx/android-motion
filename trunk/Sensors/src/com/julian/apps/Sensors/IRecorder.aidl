// Used so that RecorderService can interface with Sensors

package com.julian.apps.Sensors;

interface IRecorder {

    /**
     * Returns whether this recorder is currently recording.
     * @return True if the recorder is currently recording, False otherwise.
     */
    boolean isRecording();

    /**
     * Returns whether the service has loaded its saved data.
     * @return whether the service has loaded its saved data.
     */
    boolean isReady();
    
    /**
     * Returns the name of the file to which this recorder is recording.
     * @return The name of the file to which this recorder is recording.
     */
    String  getFilename();
    
    /**
     * Starts recording to a file with the given filename.
     * @param filename The filename of the file to which to record.
     */
    void startRecording(String filename);

    /**
     * Stops recording.
     */
    void stopRecording();
    
}
    