import serial, time
import datetime
import numpy as np


class Log :
    def __init__(self, SERIAL_PORT, SERIAL_RATE) :
        self.now = None
        self.mapping = {}
        self.mapping[0] = 'térreo'
        self.mapping[1] = '1° andar'
        self.mapping[2] = '2° andar'
        self.mapping[3] = '3° andar'
        self.init_serial(SERIAL_PORT, SERIAL_RATE)
        self.last_states = ''
        self.last_ele_calls = 0
        self.last_outside_calls = 0

    def getCurrentDateTime(self) :
        self.now = datetime.datetime.now()

    def init_serial(self, SERIAL_PORT, SERIAL_RATE) :
        self.ser = serial.Serial(SERIAL_PORT, SERIAL_RATE)

    def logCalls(self, out) :
        ele_calls = int(out[0][1], 2)
        outside_calls = int(out[1][1], 2)
        if ele_calls > self.last_ele_calls :
            for i in range(0,4) :
                bitmask = (1 << i)
                if ele_calls & bitmask and not self.last_ele_calls & bitmask :
                    print(self.now.strftime('%Y-%m-%d %H:%M:%S'), '- ', end='')
                    print('Ocorreu uma chamada de elevador no', self.mapping[i])

        if outside_calls > self.last_outside_calls :
            for i in range(0,4) :
                bitmask = (1 << i)
                if outside_calls & bitmask and not self.last_outside_calls & bitmask :
                    print(self.now.strftime('%Y-%m-%d %H:%M:%S'), '- ', end='')
                    print('Ocorreu uma chamada de andar no', self.mapping[i])
        self.last_ele_calls = ele_calls
        self.last_outside_calls = outside_calls

    # 1000 - STOP_ELE
    # 0000 - STOP
    # 0101 - DES_ELE
    # 0111 - RISE_ELE
    # 0001 - DES_OUT
    # 0011 - RISE_OUT

    '''
        E 0000
        OS 0000
        L 0
        O 0
        S 0000
        DC :
        FC 0
    '''			
    
    def logStates(self, out) :
        states = out[2][1] + out[3][1] + out[4][1]
        if (states != self.last_states) :
            print(self.now.strftime('%Y-%m-%d %H:%M:%S'), '- ', end='')
            self.last_states = states
            if not int(out[4][1],2)&1 :
                print('Parado no' , self.mapping[int(out[2][1])], end='; ')

            else :
                if int(out[4][1],2)&2 :
                    print('Subindo para o ', end='')
                    print( self.mapping[int(out[2][1]) + 1], end ='')
                else:
                    print('Descendo para o ', end='')
                    print( self.mapping[int(out[2][1]) - 1], end='')				

                print(' pela chamada do ', end='')
                if int(out[4][1],2)&4:
                    print('elevador', end ='; ')
                else :
                    print('andar', end='; ')

            if int(out[3][1]) == 2 :
                print('Porta aberta')
            elif int(out[3][1]) == 3  :
                print('Porta aberta e buzzer ligado')
            else :
                print('Porta fechada')

    def run(self) :
        mode = 1
        print('Modo programador? S\\n')
        answer = input()
        if answer == 'n':
            mode = 0

        while True:
            self.getCurrentDateTime()
            reading = self.ser.readline()
            reading = str(reading)
            arr = reading.split("_")[1:-1]
            out = []

            if not len(arr) == 7:
                continue
            else:
                for s in arr:
                    s = s.split(' ')
                    if not len(s) == 2: 
                        continue				
                    out.append( [s[0], s[1]] )

            if not len(out) == 7:
                continue

            if mode :
                for s in out:
                    if len(s[1]) == 1:
                        print(s[0] , ord(s[1])-ord('0'))
                    else :
                        print(s[0] , s[1] )
            else:
                self.logCalls(out)
                self.logStates(out)



if __name__ == "__main__":
    port = '/dev/ttyACM0'
    rate = 115200
    log = Log(port, rate)
    log.run()
