from configparser import ConfigParser
def client_extension_gen(opts):
    #Get the configparser object
    config_object = ConfigParser()
    config_object.optionxform=str
    for i in range(1,opts.client_certs):
        if config_object.has_section(' client"+str(i)+"_extensions  '):
            print("Client extension for client"+str(i)+" already exists in openssl.cnf.")
            break
        else:
            print("Writing client extension for client"+str(i)+" in openssl.cnf")
            config_object[" client"+str(i)+"_extensions "] = {
            "basicConstraints" : "CA:false",
            "keyUsage"        : "digitalSignature,keyEncipherment",
            "extendedKeyUsage" :"clientAuth",
            "subjectAltName "  :"@client_alt_names"
            }

    #Write the above sections to openssl.cnf file
    with open('../basic/openssl.cnf', 'a') as conf:
        config_object.write(conf)