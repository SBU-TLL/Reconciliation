import pycurl
url="https://apps.tlt.stonybrook.edu/reconciliation/api/public/generate_master_doc_htpass?download=true"
user="reconciliation"
password = "r3c0nc1l1at10n"
curl = pycurl.Curl()
curl.setopt(pycurl.URL, url)
curl.setopt(pycurl.SSL_VERIFYPEER, 0)

curl.setopt(pycurl.HTTPAUTH, pycurl.HTTPAUTH_BASIC)
curl.setopt(pycurl.USERPWD, "{}:{}".format(user, password))

curl.perform()
curl.close()
# from io import BytesIO
# buffer=BytesIO ()
# c=pycurl.Curl ()
# c.setopt (c.URL, url)
# c.setopt (c.WRITEDATA, buffer)
# c.setopt (c.HTTPAUTH, c.HTTPAUTH_BASIC)
# c.setopt (c.USERPWD, "%s:%s" %(user,password))
# c.perform ()
# #print ("status:%d"%c.getinfo (c.response_code))
# print (buffer.getvalue ())
# c.close ()