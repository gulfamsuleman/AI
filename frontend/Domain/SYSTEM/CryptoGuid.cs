using System;
using System.Security.Cryptography;
using System.Collections;

namespace QProcess.Domain.SYSTEM
{
    public static class CryptoGuid
    {
        public static Guid NewV4v1Guid()
        {
            using (var rand = RandomNumberGenerator.Create())
            {
                //v4 GUID; should be random *except*...
                var bytes = new byte[16];
                rand.GetBytes(bytes);
                //... the first "nibble" of the 7th byte of the sequence must be "4" (0100)
                bytes[7] = (byte)((bytes[7] & 15) | 64);
                //... and the first two bits of the 9th byte must be "10"
                bytes[8] = (byte)((bytes[8] & 63) | 128);
                return new Guid(bytes);
            }
        }

        public static Guid NewV4v2Guid()
        {
            using (var rand = RandomNumberGenerator.Create())
            {
                //v4 legacy GUID; should be random *except*...
                var bytes = new byte[16];
                rand.GetBytes(bytes);
                //... the first "nibble" of the 7th byte of the sequence must be "4" (0100)
                bytes[7] = (byte)((bytes[7] & 15) | 64);
                //... and the first two bits of the 9th byte must be "110"
                bytes[8] = (byte)((bytes[8] & 31) | 192);
                return new Guid(bytes);
            }
        }

        private static volatile ushort _randCtr;

        static CryptoGuid()
        {
            using (var rand = RandomNumberGenerator.Create())
            {
                var bytes = new byte[4];
                rand.GetBytes(bytes);
                _randCtr = BitConverter.ToUInt16(bytes, 0);
            }
        }

        public static Guid NewV7Guid(bool useCounter = false)
        {
            using (var rand = RandomNumberGenerator.Create())
            {
                //v7 GUID starts with a 48-bit Unix timestamp with millisecond precision                 
                var unix = (ulong)DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1)).TotalMilliseconds;
                //Console.WriteLine(unix);
                var unixBytes = BitConverter.GetBytes(unix);

                //Most of the rest of the GUID is random, so we may as well fill the mold
                var bytes = new byte[16];
                rand.GetBytes(bytes);                

                //Set the first 6 bytes from the timestamp 
                //Weird System.Guid constructor behavior; most significant bits are going in the second group
                //So start with index 2 and wrap around
                for (var i = 0; i < 6; i++)
                    bytes[i] = unixBytes[(i + 2) % 6];

                //The 12 bits from the lower nibble of the 7th through the 8th are either a counter or random
                if (useCounter)
                {
                    var ctrBytes = BitConverter.GetBytes(_randCtr);
                    //again, weird GUID storage thing, first two groups are MSB, last 3 are LSB
                    //so the 8th byte in the formatted string is actually index 6
                    bytes[6] = ctrBytes[0];
                    bytes[7] = ctrBytes[1];
                    _randCtr++;
                }

                //... the first "nibble" of the 7th byte of the sequence must be "7" (0111)
                bytes[7] = (byte)((bytes[7] & 15) | 112);
                //... and the first two bits of the 9th byte must be "10"
                bytes[8] = (byte)((bytes[8] & 63) | 128);

                return new Guid(bytes);
            }
        }        

        public static Guid NewGuid() => NewV4v1Guid();

        public static BitArray Reverse(this BitArray array)
        {
            var toRet = new BitArray(array);
            int length = toRet.Length;
            int mid = (length / 2);

            for (int i = 0; i < mid; i++)
            {
                bool bit = toRet[i];
                toRet[i] = toRet[length - i - 1];
                toRet[length - i - 1] = bit;
            }
            return toRet;
        }

        public static byte[] ToByteArray(this BitArray bits)
        {
            byte[] ret = new byte[(bits.Length - 1) / 8 + 1];
            bits.CopyTo(ret, 0);
            return ret;
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

