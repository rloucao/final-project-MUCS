from Crypto.Cipher import AES
import binascii

# Your AES key (same as Arduino)
key = bytes([0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe,
            0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81])

def decrypt_aes128_ecb(encrypted_data_hex):
    """
    Decrypt AES128 ECB encrypted data (matches Arduino implementation)
    """
    try:
        # Convert hex string to bytes
        encrypted_data = binascii.unhexlify(encrypted_data_hex)
        
        # Create AES cipher in ECB mode
        cipher = AES.new(key, AES.MODE_ECB)
        
        # Decrypt the data
        decrypted_data = cipher.decrypt(encrypted_data)
        
        # Remove null byte padding (like Arduino does)
        end_pos = len(decrypted_data)
        for i in range(len(decrypted_data) - 1, -1, -1):
            if decrypted_data[i] != 0:
                end_pos = i + 1
                break
        
        # Trim null bytes and decode
        decrypted_text = decrypted_data[:end_pos].decode('utf-8')
        
        return decrypted_text
    
    except Exception as e:
        print(f"Decryption error: {e}")
        return None