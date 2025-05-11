package com.example.shirr

import android.content.Context
import android.media.*
import java.io.*

class AudioConverter(private val context: Context) {

    fun decodeToWav(inputPath: String): String {
        println("🔧 Initializing decoder for input: $inputPath")

        val extractor = MediaExtractor()
        extractor.setDataSource(inputPath)

        var audioTrackIndex = -1
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) {
                audioTrackIndex = i
                break
            }
        }

        if (audioTrackIndex == -1) throw IllegalStateException("❌ No audio track found")

        extractor.selectTrack(audioTrackIndex)
        val format = extractor.getTrackFormat(audioTrackIndex)
        val mime = format.getString(MediaFormat.KEY_MIME)!!
        val sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        val pcmEncoding = AudioFormat.ENCODING_PCM_16BIT

        println("🎧 Selected audio track with mime=$mime, sampleRate=$sampleRate, channels=$channels")

        val codec = MediaCodec.createDecoderByType(mime)
        codec.configure(format, null, null, 0)
        codec.start()

        val outputDir = context.cacheDir
        val outputFile = File.createTempFile("decoded_", ".wav", outputDir)
        println("💾 Creating output file: ${outputFile.absolutePath}")

        val wavOut = FileOutputStream(outputFile)
        writeWavHeader(wavOut, channels, sampleRate, pcmEncoding)
        println("📝 Wrote placeholder WAV header")

        val bufferInfo = MediaCodec.BufferInfo()
        var eos = false
        var totalPcmBytes = 0
        var totalFrames = 0

        while (!eos) {
            val inputBufferIndex = codec.dequeueInputBuffer(10000)
            if (inputBufferIndex >= 0) {
                val inputBuffer = codec.getInputBuffer(inputBufferIndex)!!
                val sampleSize = extractor.readSampleData(inputBuffer, 0)

                if (sampleSize < 0) {
                    println("📭 End of stream")
                    codec.queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    eos = true
                } else {
                    val presentationTimeUs = extractor.sampleTime
                    codec.queueInputBuffer(inputBufferIndex, 0, sampleSize, presentationTimeUs, 0)
                    extractor.advance()
                }
            }

            val outputBufferIndex = codec.dequeueOutputBuffer(bufferInfo, 10000)
            if (outputBufferIndex >= 0) {
                val outputBuffer = codec.getOutputBuffer(outputBufferIndex)!!
                val pcmData = ByteArray(bufferInfo.size)
                outputBuffer.get(pcmData)
                outputBuffer.clear()

                wavOut.write(pcmData)
                totalPcmBytes += pcmData.size
                totalFrames++
                codec.releaseOutputBuffer(outputBufferIndex, false)

                if (totalFrames % 100 == 0) {
                    println("📦 Processed $totalFrames frames, ${totalPcmBytes / 1024} KB written")
                }
            }
        }

        codec.stop()
        codec.release()
        extractor.release()

        wavOut.flush()
        wavOut.close()
        println("✅ Finished writing PCM data: ${totalPcmBytes} bytes")

        // Fix header with accurate sizes
        val raf = RandomAccessFile(outputFile, "rw")
        writeWavHeader(raf, channels, sampleRate, pcmEncoding, totalPcmBytes)
        raf.close()

        println("🛠️ Fixed WAV header with actual size. File size: ${outputFile.length()} bytes")

        return outputFile.absolutePath
    }

    private fun writeWavHeader(out: OutputStream, channels: Int, sampleRate: Int, encoding: Int) {
        val header = ByteArray(44)
        out.write(header)
    }

    private fun writeWavHeader(raf: RandomAccessFile, channels: Int, sampleRate: Int, encoding: Int, pcmSize: Int) {
        val bitsPerSample = if (encoding == AudioFormat.ENCODING_PCM_16BIT) 16 else 8
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val totalDataLen = pcmSize + 36

        raf.seek(0)
        raf.writeBytes("RIFF")
        raf.writeIntLE(totalDataLen)
        raf.writeBytes("WAVE")
        raf.writeBytes("fmt ")
        raf.writeIntLE(16) // Subchunk1Size
        raf.writeShortLE(1) // PCM format
        raf.writeShortLE(channels.toShort())
        raf.writeIntLE(sampleRate)
        raf.writeIntLE(byteRate)
        raf.writeShortLE((channels * bitsPerSample / 8).toShort()) // Block align
        raf.writeShortLE(bitsPerSample.toShort())
        raf.writeBytes("data")
        raf.writeIntLE(pcmSize)

        println("🧾 WAV Header -> Channels: $channels, SampleRate: $sampleRate, BitsPerSample: $bitsPerSample, DataSize: $pcmSize")
    }

    private fun RandomAccessFile.writeIntLE(value: Int) {
        write(byteArrayOf(
            (value and 0xff).toByte(),
            ((value shr 8) and 0xff).toByte(),
            ((value shr 16) and 0xff).toByte(),
            ((value shr 24) and 0xff).toByte()
        ))
    }

    private fun RandomAccessFile.writeShortLE(value: Short) {
        write(byteArrayOf(
            (value.toInt() and 0xff).toByte(),
            ((value.toInt() shr 8) and 0xff).toByte()
        ))
    }
}
