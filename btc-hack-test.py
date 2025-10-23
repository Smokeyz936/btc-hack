# btc-hack-test.py — safe local-only test
# Generates one private key, corresponding public key and a legacy Bitcoin address
# No network calls, safe to run to validate key/address code paths.

import os
import binascii
import hashlib

try:
    import ecdsa
except ImportError:
    print("Please install 'ecdsa' (pip install ecdsa) before running this test.")
    raise


def generate_private_key():
    return binascii.hexlify(os.urandom(32)).decode('utf-8')


def private_key_to_public_key(private_key):
    sk = ecdsa.SigningKey.from_string(binascii.unhexlify(private_key), curve=ecdsa.SECP256k1)
    return '04' + binascii.hexlify(sk.verifying_key.to_string()).decode('utf-8')


def public_key_to_address(public_key):
    # Compute HASH160 of public key, add version byte, append checksum and Base58Check-encode
    pub_bytes = binascii.unhexlify(public_key)
    sha = hashlib.sha256(pub_bytes).digest()
    rip = hashlib.new('ripemd160')
    rip.update(sha)
    pre = b'\x00' + rip.digest()  # 0x00 version for mainnet
    checksum = hashlib.sha256(hashlib.sha256(pre).digest()).digest()[:4]
    full = pre + checksum
    # Base58 encoding
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    num = int.from_bytes(full, 'big')
    enc = ''
    while num > 0:
        num, rem = divmod(num, 58)
        enc = alphabet[rem] + enc
    # preserve leading zeros
    n_pad = 0
    for c in full:
        if c == 0:
            n_pad += 1
        else:
            break
    return (alphabet[0] * n_pad) + enc


def main():
    priv = generate_private_key()
    pub = private_key_to_public_key(priv)
    addr = public_key_to_address(pub)
    print('Private key (hex):', priv)
    print('Public key (hex):', pub)
    print('Address:', addr)


if __name__ == '__main__':
    main()
