package us.ihmc.aci.util.dspro.soi;

/**
 * Collection of description values used in the interface with DSPro
 * @author Rita Lenzi (rlenzi@ihmc.us) - 1/25/2016
 */
public enum DSProDescription
{
    track ("x-dspro/x-soi-track"),
    overlay ("x-dspro/x-soi-overlay"),
    sigact ("x-dspro/x-soi-sigact"),
    missionAlert ("x-dspro/x-soi-mission-missionAlert"),
    dataProduct ("x-dspro/x-soi-data-product"),
    logstat ("x-dspro/x-soi-logstat"),
    infoFulfillment ("x-dspro/x-soi-info-fulfillment"),
    infoRequirement ("x-dspro/x-soi-info-requirement"),
    fuelReport ("x-dspro/x-soi-fuel-report"),
    rapidRequest ("x-dspro/x-soi-rapid-request"),
    telemetryRequest ("x-dspro/x-soi-telemetry-request"),
    telemetryUpdate ("x-dspro/x-soi-telemetry-update"),
    intel ("x-dspro/x-soi-intel-data"),
    jpegImage ("image/jpeg"),
    pngImage ("image/png"),
    bmpImage ("image/bmp"),
    gifImage ("image/gif"),
    raw ("x-dspro/x-soi-raw-data"),
    arbitrary ("x-dspro/arbitrary-soi-message"),

    // SOI Gen 2
    enrichedInformationRequirement ("x-dspro/x-soi-enriched-information-requirement"),
    informationDeficit ("x-dspro/x-soi-information-deficit"),
    informationFulfillmentRegistry ("x-dspro/x-soi-information-fulfillment-registry"),
    informationUnfilled ("x-dspro/x-soi-information-unfilled"),
    intelEvent ("x-dspro/x-soi-intel-event"),
    intelReport ("x-dspro/x-soi-intel-report"),
    mission ("x-dspro/x-soi-mission"),
    product ("x-dspro/x-soi-product"),
    productRequest ("x-dspro/x-soi-product-request"),
    topic ("x-dspro/x-soi-topic"),
    unitTask ("x-dspro/x-soi-unit-task"),
    trackInfo ("x-dspro/x-soi-track-info"),
    soiTrackInfo ("x-dspro/x-soi-track-info"),
    soiTrackInfoAir ("x-dspro/x-soi-track-info-air"),
    soiTrackInfoGround ("x-dspro/x-soi-track-info-ground"),
    soiTrackInfoSea ("x-dspro/x-soi-track-info-sea"),
    networkHealthMessage ("x-dspro/x-soi-network-health-message"),
    vehicleStatus ("x-dspro/x-soi-vehicle-status"),
    loraReport ("x-dspro/x-soi-lora-message"),
    arlCamSensor ("x-dspro/x-soi-cam-sensor-message"),
    arlEUGSSensor ("x-dspro/x-soi-eugs-sensor-message"),
    arlBAISSensor ("x-dspro/x-soi-bais-sensor-message"),
    casevac ("x-dspro/x-soi-casevac"),

    // Phoenix
    cot ("x-dspro/x-phoenix-cot"),
    mist ("x-dspro/x-phoenix-mist"),
    missionPackage ("x-dspro/x-mission-package"),
    geoSensor ("x-dspro/x-geo-sensor"),
    phoenixTrackInfo ("x-dspro/x-phoenix-track-info"),
    phoenixTrackInfoAir ("x-dspro/x-phoenix-track-info-air"),
    phoenixTrackInfoGround ("x-dspro/x-phoenix-track-info-ground"),
    phoenixTrackInfoSea ("x-dspro/x-phoenix-track-info-sea");

    /**
     * Constructor
     * @param description dspro description
     */
    DSProDescription (String description)
    {
        _description = description;
    }

    /**
     * Gets the description value
     * @return the description value
     */
    public String value()
    {
        return _description;
    }

    /**
     * Gets the <code>DSProDescription</code> corresponding exactly to the <code>String</code> passed as input, if any
     * @param description mime type <code>String</code> to look for
     * @return the <code>DSProDescription</code> corresponding to the <code>String</code> passed as input, if any
     */
    public static DSProDescription getMatch (String description)
    {
        if (description == null) {
            return null;
        }

        for (DSProDescription dd : values()) {
            if (dd._description.equals (description)) {
                return dd;
            }
        }

        return null;
    }

    /**
     * Gets the <code>DSProDescription</code> corresponding to the <code>String</code> passed as input ignoring the case,
     * if any
     * @param description mime type <code>String</code> to look for
     * @return the <code>DSProDescription</code> corresponding to the <code>String</code> passed as input, if any
     */
    public static DSProDescription getMatchIgnoreCase (String description)
    {
        if (description == null) {
            return null;
        }

        for (DSProDescription dd : values()) {
            if (dd._description.toLowerCase().equals (description.toLowerCase())) {
                return dd;
            }
        }

        return null;
    }

    private final String _description;
}
