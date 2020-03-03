# virsh kullanımı
```
# sanal makine listesi
virsh list 

 Id    Name                           State
----------------------------------------------------
 19    vagrant-cluster_centos7-2      running
 20    vagrant-cluster_centos7-4      running
 21    vagrant-cluster_centos7-3      running

# snapshot listesi

virsh snapshot-list 19
 Name                 Creation Time             State
------------------------------------------------------------
 snapshot1            2020-03-03 14:57:54 +0300 running


# create snapshot

virsh snapshot-create 19 
Domain snapshot 1583241350 created

virsh snapshot-list 19
 Name                 Creation Time             State
------------------------------------------------------------
 1583241350           2020-03-03 16:15:50 +0300 running
 snapshot1            2020-03-03 14:57:54 +0300 running

```