ACC_REG_OUT_T = 0x0c
ACC_REG_CTRL_REG3 = 0x23
ACC_REG_CTRL_REG4 = 0x20
ACC_REG_CTRL_REG5 = 0x24
ACC_REG_CTRL_REG6 = 0x25
ACC_REG_STATUS = 0x27
    ACC_REG_STATUS_YDA =  0x02
    ACC_REG_STATUS_XYZDA = 0x80
ACC_REG_OUT_X_L = 0x28
ACC_REG_OUT_X_H = 0x29
ACC_REG_OUT_Y_L = 0x2A
ACC_REG_OUT_Y_H = 0x2B
ACC_REG_OUT_Z_L = 0x2C
ACC_REG_OUT_Z_H = 0x2D

LIS3DSH_STAT = 0x18
LIS3DSH_CTRL_REG1 = 0x21        
LIS3DSH_CTRL_REG3 = 0x23        
LIS3DSH_CTRL_REG4 = 0x20        
LIS3DSH_CTRL_REG5 = 0x24        
LIS3DSH_THRS1_1 = 0x57      
LIS3DSH_ST1_1 = 0x40        
LIS3DSH_ST1_2 = 0x41        
LIS3DSH_MASK1_B = 0x59      
LIS3DSH_MASK1_A = 0x5A      
LIS3DSH_SETT1 = 0x5B        
LIS3DSH_OUTS1 = 0x5F


function twosToSigned(twos)
    if(twos > 0x7fff) then
        return twos - 0x10000
    else
        return twos
    end    
end

function readAcc(address)
    spi.transaction(1, 0, 0, 8, 0x80 + address, 0,0,8)
    return spi.get_miso(1,0,8,1)
end

function writeAcc(address, value)
    spi.set_mosi(1, 0, 8, value)
    spi.transaction(1, 0, 0, 8, address, 8,0,0)
end

function initAccel()
    spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_HIGH, 8, 255)


    --Check Accelerometer is present
    whoAmI = readAcc(0x0f)
    print("Who_AM_I register (expect 3f): " .. string.format("%x", whoAmI))
    if (whoAmI ~= 0x3f) then
        print("No LIS3DSH detected")
        return
    end

    writeAcc(LIS3DSH_CTRL_REG4, 0x10 + 0x06)

end





function waitForData()
    print("Wait...")
    while(not bit.isset(readAcc(ACC_REG_STATUS), ACC_REG_STATUS_YDA))
    do
        tmr.wdclr()
    end
end


function readLis3dshXyz()
    print(string.format("0x%04x", readAcc(ACC_REG_OUT_X_H)*256+readAcc(ACC_REG_OUT_X_L)))
    print(string.format("0x%04x", readAcc(ACC_REG_OUT_Y_H)*256+readAcc(ACC_REG_OUT_Y_L)))
    print(string.format("0x%04x", readAcc(ACC_REG_OUT_Z_H)*256+readAcc(ACC_REG_OUT_Z_L)))
    spi.transaction(1, 0, 0, 8, 0x80 + ACC_REG_OUT_X_L, 0,0,48)
    print(string.format("0x%04x", spi.get_miso(1,0*8,8,1)+spi.get_miso(1,1*8,8,1)*256))
    print(string.format("0x%04x", spi.get_miso(1,2*8,8,1)+spi.get_miso(1,3*8,8,1)*256))
    print(string.format("0x%04x", spi.get_miso(1,4*8,8,1)+spi.get_miso(1,5*8,8,1)*256))
end

initAccel()
waitForData()
readLis3dshXyz()


