#! /usr/bin/env bash

# DOC: Test seattle gis servers

pushd "$(git rev-parse --show-toplevel)" > /dev/null

set -e
set +x

function test_url {
    local url="${1}"
    local jq_array_path="${2}"
    local expected_array_size="${3}"
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'

    response="$(curl \
        --silent \
        "${url}")"

    if ! jq --exit-status . >/dev/null 2>&1 <<<"${response}"; then
        printf "${RED}Failed to parse response${NC}\n"
        echo "--------------------------------------------------------------------"
        echo "${response}"
        exit 1
    else
        printf "${GREEN}Valid JSON${NC}\n"
    fi
    
    actual_array_size="$(jq "${jq_array_path} | length" <<<"${response}")"

    if [[ "${expected_array_size}" != "${actual_array_size:0:1}" ]]; then
        printf "${RED}Did not get the expected result count. Expected |${expected_array_size}|. Actual |${actual_array_size}|${NC}\n"
        echo "--------------------------------------------------------------------"
        echo "${response}" | jq
        exit 1
    else
        printf "${GREEN}General array counts match${NC}\n"
    fi
}

echo "Test findAddressCandidates"
findAddressCandidatesUrl="https://gisdata.seattle.gov/cosgis/rest/services/locators/AddressPoints/GeocodeServer/findAddressCandidates?Address=700+5th+Ave&City=Seattle&Region=WA&Postal=98101&f=pjson"
test_url "${findAddressCandidatesUrl}" ".candidates" 3

echo "Test serviceArea"
serviceAreaUrl="https://services.arcgis.com/Ej0PsM5Aw677QF1W/arcgis/rest/services/CITY_KC_AREA_446/FeatureServer/0/query?where=&objectIds=&geometry=%7B%22x%22%3A1271253%2C%22y%22%3A224277%2C%22spatialReference%22%3A%7B%22wkid%22%3A2926%7D%7D&geometryType=esriGeometryPoint&inSR=2926&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&outDistance=&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=false&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&returnAggIds=false&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnTrueCurves=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pjson&token="
test_url "${serviceAreaUrl}" ".fields" 5

echo "Test ssl certficate"
echo | openssl s_client -servername gisdata.seattle.gov -connect gisdata.seattle.gov:443

echo ""
