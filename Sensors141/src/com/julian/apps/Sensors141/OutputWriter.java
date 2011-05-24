package com.julian.apps.Sensors141;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import android.os.Environment;

/**
 * @author jkrause
 * Writes to file on the SD card.
 */
public class OutputWriter {

    /**
     * Name of file to write to.
     */
    private final String filename;

    /**
     * FileWriter used to write to file.
     */
    private FileWriter writer;

    /**
     * BufferedWriter used to write to file.
     */
    private BufferedWriter out;


    /**
     * Constructor.  Always appends to file.
     * @param inFilename Name of file to which this is writing.
     * @throws IOException If file-writing fails
     */
    public OutputWriter(final String inFilename) throws IOException {
        // Get correct filename, taking out bad characters and adding the
        // extension.
        this.filename = this.correctFilename(inFilename);

        // Construct the writer itself
        final File root = Environment.getExternalStorageDirectory();
        if (root.canWrite()) {
            final File testfile = new File(root, this.filename);
            this.writer = new FileWriter(testfile, true);
            this.out = new BufferedWriter(this.writer);
        } else {
            throw new IOException("Can't write for " + filename);
        }
    }

    /**
     * Closes the stream.
     * @throws IOException If flushing or closing fails.
     */
    public final void close() throws IOException {
        this.out.flush();
        this.out.close();
    }


    /**
     * Given a filename, converts invalid characters to underscores and
     * limits filename length to 32 when combined with the .acsn extension.
     * @param inFilename Filename to correct.
     * @return Filename corrected to not have any invalid characters in it.
     */
    public final String correctFilename(final String inFilename) {
        // Remove all non-alphanumeric characters that are also not . or _ and
        // replace them with _
        String newFilename = inFilename.replaceAll("[^a-zA-Z0-9._]", "_");

        // Truncate in case the filename is too long

        final int maxLength = 122; // 127 - 5 (from .acsn)
        int endIndex = newFilename.length();
        if (!(endIndex < maxLength)) {
            endIndex = maxLength;
        }

        newFilename = newFilename.substring(0, endIndex);
        // 'acsn' stands for Android Community Seismic Network
        return newFilename + ".acsn";
    }


    /**
     * Flushes the stream.
     * @throws IOException If flushing fails.
     */
    public final void flush() throws IOException {
        this.out.flush();
    }

    /**
     * Writes the given line to our file.
     * @param line The line to print to file.
     * @throws IOException If writing fails.
     */
    public final void write(final String line) throws IOException {
        this.out.write(line);
    }
}
