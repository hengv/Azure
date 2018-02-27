<<<<<<< HEAD


±¾Ä¿Â¼ÓÐÈý¸öÎÄ¼þ£º

b.csv£¬create-vhdvmfromvhdvm.ps1£¬create-vhdvmfromvhdvmdiffsa.ps1

ÆäÖÐb.csvÊÇÅäÖÃÎÄ¼þ£¬create-vhdvmfromvhdvm.ps1ºÍcreate-vhdvmfromvhdvmdiffsa.ps1Á½¸öÎÄ¼þ¶ÁÈ¡b.csvÕâ¸öÅäÖÃÎÄ¼þÖÐµÄ²ÎÊý½øÐÐvmµÄ¸´ÖÆ¡£

²ÎÊýËµÃ÷£º

location£ºchinanort»òchinaeast

oldrgname£ºÔ´VMµÄ×ÊÔ´×éÃû³Æ

vmname£ºÔ´VMµÄÃû³Æ

vnetrgname£ºÐÂVM½«Òª¼ÓÈëµÄVNETµÄ×ÊÔ´×éÃû³Æ

vnetname£ºÐÂVM½«Òª¼ÓÈëµÄVNETµÄÃû³Æ

subnetname£ºÐÂVM½«Òª¼ÓÈëµÄSubnetÃû³Æ

newrgname£ºÐÂVMµÄ×ÊÔ´×éÃû³Æ£¬Èç¹ûÃ»ÓÐ½«ÐÂ½¨

newvmname£ºÐÂVMµÄÃû³Æ

DiagStorageAccountName£ºÐÂVMÕï¶ÏµÄ´æ´¢ÕË»§Ãû³Æ£¬Èç¹ûÃ»ÓÐÕâ¸ö´æ´¢ÕË»§£¬½«ÐÂ½¨

vmsize£ºÐÂVMµÄÐÍºÅ

vmStorageType£ºÐÂVMµÄ´æ´¢ÀàÐÍ£¬Standard_LRS»òPremium_LRS

osType£ºLinux»òWindows

avsname£ºAvailability SetµÄÃû³Æ£¬Èç¹ûÃ»ÓÐ½«ÐÂ½¨

create-vhdvmfromvhdvm.ps1½«°ÑÔ´VMµÄOS diskºÍData Disk½øÐÐ¸´ÖÆ£¬²¢ÔÚÖ¸¶¨µÄVnet¼°SubnetÖÐ´´½¨NIC£¬ÔÚÖ¸¶¨µÄ×ÊÔ´×éÖÐ´´½¨Ö¸¶¨Ãû³ÆµÄVM¡£ÆäÖÐOS DiskºÍData Disk¶¼¸´ÖÆµ½Ô´VMµÄOS DiskºÍData DiskÏàÍ¬µÄ´æ´¢ÕË»§ÖÐ¡£µ«½«ÐÂ½¨Ò»¸öContainer£¬ContainerµÄÃû³ÆÊÇVMÃû³Æ+ÈÕÆÚ+6Î»Ëæ»úÊý¡£Èç¹ûVMÃû³Æ³¤¶ÈÌ«³¤£¬×Ü³¤¶ÈÊÇ24¸ö×Ö½Ú¡£¸´ÖÆ¹ý³Ì¿ÉÒÔ²»¹Ø»ú£¬µ«²»½¨Òé¶ÁÐ´´ÅÅÌ¡£µ±È»¹Ø»ú¸´ÖÆ×î°²È«¡£

create-vhdvmfromvhdvmdiffsa.ps1ºÍcreate-vhdvmfromvhdvm.ps1ÀàËÆ£¬²»Í¬Ö®´¦ÔÚÓÚ£¬¿¼ÂÇµ½Ã¿¸ö´æ´¢ÕË»§Ö»ÄÜÈÝÄÉ×î´ó40¸öDisk£¬Õâ¸ö½Å±¾½«°Ñ¸´ÖÆµÄDisk·Åµ½Ò»¸öÐÂµÄ´æ´¢ÕË»§ÖÐ¡£´æ´¢ÕË»§µÄÃû³ÆÃüÃû¹æÔòºÍÇ°ÃæÌáµ½µÄContainerµÄÃû³ÆÃüÃû¹æÔòÏàÍ¬¡£
=======
æœ¬ç›®å½•æœ‰ä¸‰ä¸ªæ–‡ä»¶ï¼š

b.csvï¼Œcreate-vhdvmfromvhdvm.ps1ï¼Œcreate-vhdvmfromvhdvmdiffsa.ps1

å…¶ä¸­b.csvæ˜¯é…ç½®æ–‡ä»¶ï¼Œcreate-vhdvmfromvhdvm.ps1å’Œcreate-vhdvmfromvhdvmdiffsa.ps1ä¸¤ä¸ªæ–‡ä»¶è¯»å–b.csvè¿™ä¸ªé…ç½®æ–‡ä»¶ä¸­çš„å‚æ•°è¿›è¡Œvmçš„å¤åˆ¶ã€‚

å‚æ•°è¯´æ˜Žï¼š

locationï¼šchinanortæˆ–chinaeast

oldrgnameï¼šæºVMçš„èµ„æºç»„åç§°

vmnameï¼šæºVMçš„åç§°

vnetrgnameï¼šæ–°VMå°†è¦åŠ å…¥çš„VNETçš„èµ„æºç»„åç§°	

vnetnameï¼šæ–°VMå°†è¦åŠ å…¥çš„VNETçš„åç§°

subnetnameï¼šæ–°VMå°†è¦åŠ å…¥çš„Subnetåç§°

newrgnameï¼šæ–°VMçš„èµ„æºç»„åç§°ï¼Œå¦‚æžœæ²¡æœ‰å°†æ–°å»º

newvmnameï¼šæ–°VMçš„åç§°

DiagStorageAccountNameï¼šæ–°VMè¯Šæ–­çš„å­˜å‚¨è´¦æˆ·åç§°ï¼Œå¦‚æžœæ²¡æœ‰è¿™ä¸ªå­˜å‚¨è´¦æˆ·ï¼Œå°†æ–°å»º	

vmsizeï¼šæ–°VMçš„åž‹å·

vmStorageTypeï¼šæ–°VMçš„å­˜å‚¨ç±»åž‹ï¼ŒStandard_LRSæˆ–Premium_LRS

osTypeï¼šLinuxæˆ–Windows

avsnameï¼šAvailability Setçš„åç§°ï¼Œå¦‚æžœæ²¡æœ‰å°†æ–°å»º
>>>>>>> d042af255236dd27bde9c91bfaf2ce54e1abc3e6
