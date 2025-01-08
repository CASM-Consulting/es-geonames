echo "Starting Docker container and data volume..."
# create the directory first to avoid permission issues when Docker is running as root
mkdir $PWD/geonames_index/
docker run -d -p 127.0.0.1:9200:9200 -e "discovery.type=single-node" -v $PWD/geonames_index/:/usr/share/elasticsearch/data elasticsearch:7.10.1 

echo "Downloading Geonames gazetteer..."
# Check whether these files already exist, if they do, skip the download
if [ -f "allCountries.zip" ]; then
    echo "allCountries.zip already exists. Skipping download."
else
    echo "Downloading allCountries.zip..."
    wget https://download.geonames.org/export/dump/allCountries.zip
fi

if [ -f "admin1CodesASCII.txt" ]; then
    echo "admin1CodesASCII.txt already exists. Skipping download."
else
    echo "Downloading admin1CodesASCII.txt..."
    wget https://download.geonames.org/export/dump/admin1CodesASCII.txt
fi

if [ -f "admin2Codes.txt" ]; then
    echo "admin2Codes.txt already exists. Skipping download."
else
    echo "Downloading admin2Codes.txt..."
    wget https://download.geonames.org/export/dump/admin2Codes.txt
fi

# Check if 'allCountries.txt' exists, if not unpack the zip file
if [ -f "allCountries.txt" ]; then
    echo "allCountries.txt already exists. Skipping unpacking."
else
    echo "Unpacking Geonames gazetteer..."
    unzip allCountries.zip
fi

echo "Creating mappings for the fields in the Geonames index..."
curl -XPUT 'localhost:9200/geonames' -H 'Content-Type: application/json' -d @geonames_mapping.json

echo "Change disk availability limits..."
curl -X PUT "localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
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
python geonames_elasticsearch_loader.py

echo "Done"