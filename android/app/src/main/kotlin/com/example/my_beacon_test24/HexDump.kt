package com.example.my_beacon_test24

import android.util.Log

class HexDump {
    companion object {
        //           1         2         3         4         5         6         7
        // 012345678901234567890123456789012345678901234567890123456789012345678901234567890
        // 01234567: 00 11 22 33 44 55 66 77 - 88 99 AA BB CC DD EE FF : abcdefghijklmnop
        private fun get4bUpper(b : Int) : Char {
            val n = b.and(0x0F)
            return if (n < 10) {
                '0' + n
            } else {
                'A' + (n - 10)
            }
        }

        private fun putHexStringUpperByte(line : Array<Char>, index : Int, n : Int) : Int {
            var v = n
            for (j in 1 downTo 0) {
                line[index + j] = get4bUpper(v)
                v = v.shr(4)
            }
            return index + 2
        }

        private fun putHexStringUpperIntToLineTop(line : Array<Char>, n : Int) : Int {
            var v = n
            for (j in 7 downTo 0) {
                line[j] = get4bUpper(v)
                v = v.shr(4)
            }
            return 8
        }

        fun IntToHexString(v : Int) : String {
            val line = Array(8) { ' ' }
            putHexStringUpperIntToLineTop(line, v)
            return String(line.toCharArray())
        }

        fun dump(b : ByteArray, addr : Int, length : Int) {
            val line = Array(78) { ' ' }
            line[8] = ':'
            line[34] = '-'
            line[60] = ':'
            var xaddr = addr
            var ptr = addr
            var column = 15
            for (i in 0 until length) {
                column = (i % 16)
                if (column == 0) {
                    // ascii 部分を空白でクリア.
                    for (j in 62 until 78) {
                        line[j] = ' '
                    }
                    putHexStringUpperIntToLineTop(line, xaddr)
                    xaddr += 16
                }
                val v = b[ptr++].toInt()
                line[62 + column] = if ((v >= 0x20) && (v < 0x7F)) {
                    v.toChar()
                } else {
                    '.'
                }
                val pos = if (column < 8) {
                    10 + (3 * column)
                } else {
                    12 + (3 * column)
                }
                putHexStringUpperByte(line, pos, v)

                if (column == 15) {
                    //println("line:${String(line.toCharArray())}")
                    Log.i(Const.TAG, String(line.toCharArray()))
                }
            }
            if (column != 15) {
                column++
                val pos = if (column < 8) {
                    10 + (3 * column)
                } else {
                    12 + (3 * column)
                }
                for (i in pos until 59) {
                    line[i] = ' '
                }
                for (i in (62 + column) until 78) {
                    line[i] = ' '
                }
                //println("line:${String(line.toCharArray())}")
                Log.i(Const.TAG, String(line.toCharArray()))
            }
        }
    }
}