#!/bin/bash

# Check if the remote Elasticsearch host is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <REMOTE_ELASTICSEARCH_HOST>"
  exit 1
fi

REMOTE_ELASTICSEARCH_URL=$1

echo "Assuming remote Elasticsearch container is running at $REMOTE_ELASTICSEARCH_URL..."

echo "Downloading Geonames gazetteer..."
wget https://download.geonames.org/export/dump/allCountries.zip
wget https://download.geonames.org/export/dump/admin1CodesASCII.txt
wget https://download.geonames.org/export/dump/admin2Codes.txt
echo "Unpacking Geonames gazetteer..."
unzip allCountries.zip

echo "Creating mappings for the fields in the Geonames index..."
curl -XPUT "http://$REMOTE_ELASTICSEARCH_URL/geonames" -H 'Content-Type: application/json' -d @geonames_mapping.json

echo "Change disk availability limits..."
curl -X PUT "http://$REMOTE_ELASTICSEARCH_URL/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "transient": {
    "cluster.routing.allocation.disk.watermark.low": "10gb",
    "cluster.routing.allocation.disk.watermark.high": "5gb",
    "cluster.routing.allocation.disk.watermark.flood_stage": "4gb",
    "cluster.info.update.interval": "1m"
  }
}
'

echo "\nLoading gazetteer into Elasticsearch..."
python geonames_elasticsearch_loader.py --url $REMOTE_ELASTICSEARCH_URL

echo "Done"
