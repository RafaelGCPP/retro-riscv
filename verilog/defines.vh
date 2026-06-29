    `ifdef VERILATOR

        `ifndef FIRMWARE_FILE_PATH
            `define FIRMWARE_FILE_PATH "../firmware/build/verilator/firmware.hex"
        `endif

    `else
        `ifndef FIRMWARE_FILE_PATH
            `define FIRMWARE_FILE_PATH "../firmware/build/tang20k/firmware.hex"
        `endif
        
    
    `endif