package us.ihmc.aci.util.dspro.soi;

/**
 * Collection of mime type values used in the interface with DSPro
 *
 * @author Rita Lenzi (rlenzi@ihmc.us) - 1/22/2016
 */
public enum DSProMimeType {
    track("x-dspro/x-soi-track"),
    overlay("x-dspro/x-soi-overlay"),
    sigact("x-dspro/x-soi-sigact"),
    missionAlert("x-dspro/x-soi-mission-missionAlert"),
    dataProduct("x-dspro/x-soi-data-product"),
    logstat("x-dspro/x-soi-logstat"),
    infoFulfillment("x-dspro/x-soi-info-fulfillment"),
    infoRequirement("x-dspro/x-soi-info-requirement"),
    fuelReport("x-dspro/x-soi-fuel-report"),
    rapidRequest("x-dspro/x-soi-rapid-request"),
    telemetryRequest("x-dspro/x-soi-telemetry-request"),
    telemetryUpdate("x-dspro/x-soi-telemetry-update"),
    intel("x-dspro/x-soi-intel-data"),
    jpegImage("image/jpeg"),
    pngImage("image/png"),
    bmpImage("image/bmp"),
    gifImage("image/gif"),
    raw("x-dspro/x-soi-raw-data"),
    arbitrary("x-dspro/arbitrary-soi-message"),

    // SOI Gen 2
    enrichedInformationRequirement("x-dspro/x-soi-enriched-information-requirement"),
    informationDeficit("x-dspro/x-soi-information-deficit"),
    informationFulfillmentRegistry("x-dspro/x-soi-information-fulfillment-registry"),
    informationUnfilled("x-dspro/x-soi-information-unfilled"),
    intelEvent("x-dspro/x-soi-intel-event"),
    intelReport("x-dspro/x-soi-intel-report"),
    mission("x-dspro/x-soi-mission"),
    product("x-dspro/x-soi-product"),
    productRequest("x-dspro/x-soi-product-request"),
    topic("x-dspro/x-soi-topic"),
    unitTask("x-dspro/x-soi-unit-task"),
    soiTrackInfo("x-dspro/x-soi-track-info"),
    soiTrackInfoAir("x-dspro/x-soi-track-info-air"),
    soiTrackInfoGround("x-dspro/x-soi-track-info-ground"),
    soiTrackInfoSea("x-dspro/x-soi-track-info-sea"),
    networkHealthMessage("x-dspro/x-soi-network-health-message"),
    vehicleStatus("x-dspro/x-soi-vehicle-status"),
    loraReport("x-dspro/x-soi-lora-message"),
    //arlCamSensor ("x-dspro/x-soi-cam-sensor-message"),
    arlEUGSSensor("x-dspro/x-soi-eugs-sensor-message"),
    arlBAISSensor("x-dspro/x-soi-bais-sensor-message"),
    casevac("x-dspro/x-soi-casevac"),

    // Phoenix
    mist("x-dspro/x-phoenix-mist"),
    missionPackage("x-dspro/x-mission-package"),
    geoSensor("x-dspro/x-geo-sensor"),
    phoenixTrackInfo("x-dspro/x-phoenix-track-info"),
    phoenixTrackInfoAir("x-dspro/x-phoenix-track-info-air"),
    phoenixTrackInfoGround("x-dspro/x-phoenix-track-info-ground"),
    phoenixTrackInfoSea("x-dspro/x-phoenix-track-info-sea"),

    // Cot
    cot("x-dspro/x-cot"),
    cotImage("x-dspro/x-cot.image"),
    cotText("x-dpro/x-cot.text"),

    // Mission Package
    dsproMissionPackage("application/vnd.mission-package"),
    zip("application/zip"),
    zipMissionPackage("application/x-zip-compressed");


    /**
     * Constructor
     *
     * @param mimeType mime type value
     */
    DSProMimeType(String mimeType) {
        _mimeType = mimeType;
    }

    /**
     * Gets the mime type value
     *
     * @return the mime type value
     */
    public String value() {
        return _mimeType;
    }

    /**
     * Gets the <code>DSProMimeType</code> corresponding exactly to the <code>String</code> passed as input, if any
     *
     * @param mimeType mime type <code>String</code> to look for
     * @return the <code>DSProMimeType</code> corresponding to the <code>String</code> passed as input, if any
     */
    public static DSProMimeType getMatch(String mimeType) {
        if (mimeType == null) {
            return null;
        }

        for (DSProMimeType dmt : values()) {
            if (dmt._mimeType.equals(mimeType)) {
                return dmt;
            }
        }

        return null;
    }

    /**
     * Gets the <code>DSProMimeType</code> corresponding to the <code>String</code> passed as input ignoring the case,
     * if any
     *
     * @param mimeType mime type <code>String</code> to look for
     * @return the <code>DSProMimeType</code> corresponding to the <code>String</code> passed as input, if any
     */
    public static DSProMimeType getMatchIgnoreCase(String mimeType) {
        if (mimeType == null) {
            return null;
        }

        if ((mimeType.equals("image/jpeg")) || (mimeType.equals("image/jpg"))) {
            return jpegImage;   // This is necessary to handle both the strings
        }

        for (DSProMimeType dmt : values()) {
            if (dmt._mimeType.toLowerCase().equals(mimeType.toLowerCase())) {
                return dmt;
            }
        }

        return null;
    }

    /**
     * Retrieves the mime type corresponding to the given image extension
     *
     * @param ext image extension
     * @return the mime type corresponding to the given image extension if any, null otherwise
     */
    public static DSProMimeType getImageMimetype(String ext) {
        if (ext == null) {
            return null;
        }

        if ((ext.endsWith("jpg")) || (ext.endsWith("jpeg"))) {
            return jpegImage;
        }

        if (ext.endsWith("png")) {
            return pngImage;
        }

        if (ext.endsWith("bmp")) {
            return bmpImage;
        }

        if (ext.endsWith("gif")) {
            return gifImage;
        }

        return null;
    }

    /**
     * Gets the image extension corresponding to the given mimetype
     *
     * @param mimetype image mimetype
     * @return the image extension corresponding to the given mimetype
     */
    public static String getImageExt(String mimetype) {
        if (mimetype == null) {
            return null;
        }

        DSProMimeType mt = getMatchIgnoreCase(mimetype);
        if (mt == null) {
            return null;
        }

        switch (mt) {
            case jpegImage:
                return "jpg";

            case pngImage:
                return "png";

            case bmpImage:
                return "bmp";

            case gifImage:
                return "gif";

            default:
                return null;
        }
    }

    /**
     * Retrieves the string representation of the mime type corresponding to the given image extension
     *
     * @param ext image extension
     * @return the string representation of the mime type corresponding to the given image extension if any,
     * null otherwise
     */
    public static String getStringImageMimetype(String ext) {
        DSProMimeType mimeType = getImageMimetype(ext);
        if (mimeType == null) {
            return null;
        }

        return mimeType.value();
    }

    private final String _mimeType;
}
