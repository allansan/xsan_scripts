# luncheck

> @allansan  
> 2017  

**Description**:

1. Count LUNs using `cvlabel` until we have the correct number for the SANvol
2. When all LUNs are present, mount all  SANvols listed by `xsanctl`

**Assumptions**: 

* mount all Xsan volumes available
* will be run as 'root' via LaunchDaemon
* `xsand` is configured and running
* all target Xsan nodes running on same OS version

**Customisation**: 

* `LOGIDENT` = set this to suit your environment
* `ALLLUNS` = total # LUNs which comprise your SANvol(s)
* `MAXWAIT` = total number of times we’re going to loop
* `SLEEP` = a “sensible” time to wait between `cvlabel` runs

**Installation**:

```
sudo cp com.10dot1.luncheck.plist /Library/LaunchDaemons/
sudo chmod 644 /Library/LaunchDaemons/com.10dot1.luncheck.plist
sudo chown 0:0 /Library/LaunchDaemons/com.10dot1.luncheck.plist
sudo mkdir -p /Library/Scripts/Xsan/
sudo cp luncheck.sh /Library/Scripts/Xsan/luncheck.sh
sudo chmod 755 /Library/Scripts/Xsan/luncheck.sh
sudo chown 0:0 /Library/Scripts/Xsan/luncheck.sh

```

**Trying to be helpful**

If you’re unsure how many LUNs you have in your environment, you should be able to find out by running the following on your MDC. This does assume that all LUNs in your fabric are labelled and in use:

```
sudo for vol in ${SANLIST[@]}; do 
	echo $vol
	cvadmin -e "select $vol" -e "show long" | grep -c Node
done
```

Sample output:

```
WorkSAN
22
ArchiveSAN
5
```
