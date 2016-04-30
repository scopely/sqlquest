krb5 = require 'krb5'
k = krb5
  principal: 'jenkins@HIPPOS.SCOPELY.IO'
  keytab: '/etc/keytabs/jenkins.keytab' # If password not set, default keytab if not defined
  service_principal: 'hive'
  renew: true

k.kinitSync();
console.log 'k:', k

