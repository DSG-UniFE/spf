package us.ihmc.aci.util.dspro.soi;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.text.DecimalFormat;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author Giacomo Benincasa    (gbenincasa@ihmc.us)
 */
public class Track
{    
    public final String _name;
    public final double _latitude;
    public final double _longitude;
    private final String _milStd2552;
    private final String _date;
    private final long _timestamp;
    private final DecimalFormat _formatter;

    public Track (String name, double latitude, double longitude, String milStd2552)
    {
        this(name, latitude, longitude, milStd2552, new Date());
    }

    public Track (String name, double latitude, double longitude, String milStd2552, Date d)
    {
        _name = name;
        _latitude = latitude;
        _longitude = longitude;
        _milStd2552 = milStd2552;
        _timestamp = System.currentTimeMillis();
        DateFormat df = new SimpleDateFormat("yyyy-MM-d");
        String date = df.format(d);
        df = new SimpleDateFormat("HH:mm:ss.S");
        String time = df.format(d);
        _date = date + "T" + time + "Z";
        _formatter = new DecimalFormat("0.############E0");
    }
    
    /**
      {
        "track" : {
            "milStd2525Symbol" : {
            "milStd2525SymbolId" : "SFGPUCI----E***"
        },
        "trackType" : "Unit",
        "identifiers" : {
        "uid" : "M11163",
        "nickname" : "A Co"
        }
      },
        "events" : [ {
            "date" : "2016-03-01T15:36:28.718Z",
            "location" : {
                "position" : {
                    "latitude" : "35.6121826171875",
                    "longitude" : "-82.55401611328125"
                }
            },
        "source" : "observed"
        } ]
     }
     * @return 
     */
    public String toJson()
    {
        String pattern = "{\n" +
            "  \"track\" : {\n" +
            "    \"trackType\" : \"Unit\",\n" +
            "    \"environmentCategory\" : \"LND\",\n" +
            "    \"threat\" : \"FRD\",\n" +
            "    \"name\" : \"%s\",\n" +
            "    \"milStd2525Symbol\" : \"%s\",\n" +
            "    \"identifiers\" : {\n" +
            "      \"uid\" : \"%s\",\n" +
            "      \"nickname\" : \"%s\"\n" +
            "    }\n" +
            "  },\n" +
            "  \"events\" : [ {\n" +
            "    \"dtg\" : %s,\n" +
            "    \"location\" : {\n" +
            "      \"position\" : {\n" +
            "        \"latitude\" : %f,\n" +
            "        \"longitude\" : %f\n" +
            "      }\n" +
            "    },\n" +
            "    \"classification\" : \"UNKNOWN\",\n" +
            "    \"source\" : \"Observed\"\n" +
            "  } ]\n" +
            "}";

        String id;
        try {
            id = SOIIDGen.genId(_name);
        } catch (Exception ex) {
            Logger.getLogger(Track.class.getName()).log(Level.SEVERE, null, ex);
            id = "AAA000000000";    
        }

        String result = String.format(pattern, _name, _milStd2552, id, _name,
                _formatter.format(_timestamp), _latitude, _longitude);
        return result;
    }
}
