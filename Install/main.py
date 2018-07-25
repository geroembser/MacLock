import tempfile  # for temp files
import urllib2  # for downloading
import subprocess  # for unzipping
import os  # for opening app

version = "1.0"
download_url = "https://github.com/geroembser/MacLock/releases/download/v"+version+"/MacLock.app.zip"
applications_path = "/Applications/"
destination_path = applications_path+"MacLock.app"

# make sure, no MacLock app exists at destination path
if os.path.isdir(destination_path):
    print("Found an existing version of MacLock. To update, remove that version.")
    # todo: improve handling like this...
    exit(1)

# file name
file_name = download_url.split('/')[-1]

u = urllib2.urlopen(download_url)

# new temp file
f = tempfile.NamedTemporaryFile()
f.delete = False # don't delete

meta = u.info()
file_size = int(meta.getheaders("Content-Length")[0])
print "Downloading: %s Bytes: %s" % (file_name, file_size)

file_size_dl = 0 # file size
block_sz = 8192 # blocks
while True:
    buffer = u.read(block_sz) # read buff
    if not buffer:
        break # break loop

    file_size_dl += len(buffer)
    f.write(buffer) # writing buffer

    # printing status...
    status = r"%10d  [%3.2f%%]" % (file_size_dl, file_size_dl * 100. / file_size)
    status = status + chr(8)*(len(status)+1)
    print status

# close file
f.close()

print("Download completed!!!")

# unzip (using macs built in unzip, because python unzip result in gatekeeper errors)
print("unzipping...")
subprocess.call(["unzip",f.name, "-d", applications_path], stdout=open(os.devnull, 'wb'))

# unzipped...
print("unzipped")

# open
print("opening...")
os.system("open "+destination_path)

# delete temp file at the end
os.remove(f.name)