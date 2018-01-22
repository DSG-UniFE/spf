package us.ihmc.chunking;

import java.util.Collection;
import java.util.List;

/**
 *
 * @author Giacomo Benincasa    (gbenincasa@ihmc.us)
 */
public interface Fragmenter
{    
    public List<ChunkWrapper> fragment (byte[] data, String inputMimeType,
                                        byte nChunks, byte compressionQuality);
    public byte[] extract (byte[] data, String inputMimeType, byte nChunks,
                           byte compressionQuality, Collection<Interval> intervals);
}
