package us.ihmc.aci.util.dspro;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.StringReader;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;
import us.ihmc.util.ByteArray;

/**
 *
 * @author Giacomo Benincasa    (gbenincasa@ihmc.us)
 */
public class XMLMetadataParser
{   
    public static HashMap<String, String> parse (byte[] xml) throws XMLStreamException
    {
        return parse (ByteArray.byteArrayToString(xml, 0, xml.length));
    }

    public static HashMap<String, String> parse (String xml) throws XMLStreamException
    {
        return parse (XMLInputFactory.newInstance().createXMLStreamReader(new StringReader(xml)));
    }

    public static HashMap<String, String> parse (File xmlFile) throws XMLStreamException, FileNotFoundException
    {
        return parse (XMLInputFactory.newInstance().createXMLStreamReader(new FileReader(xmlFile)));
    }

    public static HashMap<String, String> parse (XMLStreamReader reader) throws XMLStreamException
    {
        HashMap<String, Object> map = parseAndCast (reader);
        if (map == null) {
           return null;
        }
        HashMap<String, String> sMap = new HashMap<String, String>();
        for (Entry<String, Object> e : map.entrySet()) {
            sMap.put(e.getKey(), e.getValue().toString());
        }
        return sMap;
    }
 
    public static HashMap<String, Object> parseAndCast (XMLStreamReader reader) throws XMLStreamException
    {
        while (reader.hasNext()) {
            int type = reader.next();
            if (reader.getEventType() == XMLStreamReader.START_ELEMENT && "Metadata".equalsIgnoreCase(reader.getLocalName())) {
                HashMap<String, Object> properties = new HashMap<String, Object>();
                String name, value;
                while (reader.hasNext()) {
                    type = reader.next();
                    if (type == XMLStreamReader.START_ELEMENT) {
                        if ( "Field".equalsIgnoreCase(reader.getLocalName())) {
                            // Go to the next element
                            do {
                                type = reader.next();
                            } while (reader.hasNext() && (type != XMLStreamReader.START_ELEMENT));
                            name = value = null;
                            if ( "FieldName".equalsIgnoreCase(reader.getLocalName())) {
                                name = reader.getElementText();
                                //System.out.println(name);
                            }
                            do {
                                type = reader.next();
                            } while (reader.hasNext() && (type != XMLStreamReader.START_ELEMENT));
                            if ( "FieldValue".equalsIgnoreCase(reader.getLocalName())) {
                                value = reader.getElementText();
                            }
                            if (name != null && value != null && !value.equals("") && !value.equals("UNKNOWN")) {
                                if (name.equals(MetadataElement.Left_Upper_Latitude.toString()) ||
                                    name.equals(MetadataElement.Right_Lower_Latitude.toString()) ||
                                    name.equals(MetadataElement.Left_Upper_Longitude.toString()) ||
                                    name.equals(MetadataElement.Right_Lower_Longitude.toString())) {
                                    properties.put(name, new Float(value));
                                }
                                else if (name.equals(MetadataElement.Receiver_Time_Stamp.toString()) ||
                                    name.equals(MetadataElement.Source_Time_Stamp.toString()) ||
                                    name.equals(MetadataElement.Expiration_Time.toString())) {
                                    properties.put(name, new Long(value));
                                }
                                else {
                                    properties.put(name, value);
                                }
                            }
                        }
                    }
                }
                return properties;
            }
        }
        return null;
    }

    static public String toXML (Map<Object, Object> props)
    {
        return toXML (props.keySet(), props.values());
    }

    static public String toXML (Collection keys, Collection values)
    {
        final String XML_HEADER = "<?xml version=\"1.0\"?>";
        final String XML_METADATA_ELEMENT = "Metadata";

        StringBuilder xmlDoc = new StringBuilder (XML_HEADER)
                .append ("\n")
                .append ("<").append (XML_METADATA_ELEMENT).append (">");
        
        Iterator kIt = keys.iterator();
        Iterator vIt = values.iterator();

        while (kIt.hasNext() && vIt.hasNext()) {
            Object key = kIt.next();
            Object val = vIt.next();
            xmlDoc.append ("\n\t<Field>")
                    .append ("\n\t\t<FieldName>").append(key.toString()).append("</FieldName>")
                    .append("\n\t\t<FieldValue>").append(val.toString()).append("</FieldValue>")
                    .append ("\n\t</Field>");
        }

        xmlDoc.append("\n");
        xmlDoc.append("</").append(XML_METADATA_ELEMENT).append(">");
        return xmlDoc.toString();
    }
}
