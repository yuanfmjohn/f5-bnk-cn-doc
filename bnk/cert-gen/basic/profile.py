#!/usr/bin/env python3

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2007-2014 VMware, Inc. or its affiliates. All rights reserved.
# Copyright (c) 2014-2020 Michael Klishin and contributors.

import sys
import os
import shutil
from glob import glob

def _copy_artifacts_to_results(opts):
    os.makedirs(paths.relative_path("result"), exist_ok = True)
    gen.copy_root_ca_certificate_and_key_pair()
    gen.copy_leaf_certificate_and_key_pair("server")
    gen.copy_leaf_certificate_and_key_pair("client")
    n_certs=opts.client_certs
    for i in range(1,n_certs):
        gen.copy_leaf_certificate_and_key_pair("client"+str(i))
    

def generate(opts):
    cli.validate_password_if_provided(opts)
    print("Will generate a root CA and two certificate/key pairs (server and client)")
    gen.generate_root_ca(opts)
    gen.generate_server_certificate_and_key_pair(opts)
    gen.generate_client_certificate_and_key_pair(opts)
    _copy_artifacts_to_results(opts)
    print("Done! Find generated certificates and private keys under ./result!")

def clean(opts):
    path = os.getcwd()
    pattern = os.path.join(path, "client*")
    for item in glob(pattern):
        if not os.path.isdir(item):
            continue
        shutil.rmtree(item)
    n_certs=opts.client_certs
    for i in range(1,n_certs):
        for s in [paths.root_ca_path(),
                paths.result_path(),
                paths.leaf_pair_path("server"),
                paths.leaf_pair_path("client"+str(i)),
                paths.leaf_pair_path("client")]:
            print("Removing {}".format(s))
            try:
                shutil.rmtree(s)
            except FileNotFoundError:
                pass
    print("Creating "+str(n_certs)+" client extensions...")
    extension_gen.client_extension_gen(opts)

def regenerate(opts):
    clean(opts)
    generate(opts)

def verify(opts):
    n_certs=opts.client_certs
    print("Will verify generated server certificate against the CA...")
    verify.verify_leaf_certificate_against_root_ca("server")
    print("Will verify generated client certificate against the CA...")
    verify.verify_leaf_certificate_against_root_ca("client")
    for i in range(1,n_certs):
        print("Will verify generated client"+str(i)+" certificate against the CA...")
        verify.verify_leaf_certificate_against_root_ca("client"+str(i))
  

def verify_pkcs12(opts):
    cli.validate_password_if_provided(opts)
    print("Will verify generated PKCS12 certificate stores...")
    verify.verify_pkcs12_store("client", opts)
    n_certs=opts.client_certs
    for i in range(1,n_certs):
        verify.verify_pkcs12_store("client"+str(n_certs), opts)
    verify.verify_pkcs12_store("server", opts)

def info(opts):
    info.leaf_certificate_info("client")
    info.leaf_certificate_info("server")
    info.leaf_certificate_info("client"+str(opts.client_cert))

commands = {"generate":   generate,
            "gen":        generate,
            "clean":      clean,
            "regenerate": regenerate,
            "regen":      regenerate,
            "verify":     verify,
            "verify-pkcs12": verify_pkcs12,
            "info":       info}

if __name__ == "__main__":
    sys.path.append("..")
    from tls_gen import extension_gen
    from tls_gen import cli
    from tls_gen import gen
    from tls_gen import paths
    from tls_gen import verify
    from tls_gen import info

    cli.run(commands)
