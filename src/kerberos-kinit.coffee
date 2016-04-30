krb5 = require 'krb5'
k = krb5
  principal: 'datamart@HIPPOS.SCOPELY.IO'
  keytab: '/etc/keytabs/datamart.keytab' # If password not set, default keytab if not defined
  service_principal: 'hive'
  renew: true

k.kinitSync();
console.log 'k:', k

