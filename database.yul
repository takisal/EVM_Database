object "Database" {
    code {
        // Store the address of the deployer in storage slot (0)
        // Storage slot 0 is where the address of the contract owner is stored
        sstore(0, caller())


        // Deploy the contract
        datacopy(0, dataoffset("runtimeDB"), datasize("runtimeDB"))
        return(0, datasize("runtimeDB"))
    }
    object "runtimeDB" {
        code {
            // Protection against sending Ether
            require(iszero(callvalue()))

            // Dispatcher
            switch selector()
            case 0x0000eb1c /* "get data using key" function */ {
                returnUint(retrieveData(decodeAsUint(0)))
            }
            case 0x00001337 /* "enter data using key and value" function */ {
                storeData(decodeAsUint(0), decodeAsUint(1))
                //returns true bool
                returnUint(1)
            }
            case 0x0000eccc /* "get current owner" function */ {
                returnAddress(getDBOwner())
            }
            case 0x11cc0000 /* "change owner" function */ {
                require(calledByOwner())
                returnUint(changeDBOwner(decodeAsAddress(0)))
            }
            default {
                //if no matching function signatures, revert
                revert(0, 0)
            }
            

            /* ---------- calldata decoding functions ----------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }
            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }
            /* ---------- encoding functions for return calldata ---------- */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }
            function returnAddress(v) {
                mstore(0, v)
                return(0, 0x14)
            }
            

            /* -------- events ---------- */
            function emitStored(key, storedValue, storer) {
                let signatureHash := 0x670db1fe9b90aaa577567c0329308e4a26523d30772da3da12751cdae673f900
                emitEvent(signatureHash, key, storedValue, storer)
            }
            function emitEvent(signatureHash, indexed1, indexed2, nonIndexed) {
                mstore(0, nonIndexed)
                log3(0, 0x20, signatureHash, indexed1, indexed2)
            }

            /* -------- storage layout ---------- */
            function keyOffset(key) -> offset {
                mstore(0, key)
                offset := keccak256(0, 0x20)
            }

            /* -------- storage access ---------- */
            function retrieveData(key) -> storedValue {
                storedValue := sload(keyOffset(key))
            }
            function storeData(key, valueToStore) {
                let storageLocation := keyOffset(key)
                sstore(storageLocation, valueToStore) 
            }
            function getDBOwner() -> owner {
                owner := sload(0)
            }
            function changeDBOwner(newOwner) -> trueBool {
                sstore(0, newOwner)
                trueBool := 1
            }
            

            /* ---------- utility functions ---------- */
            function calledByOwner() -> calledByOwnerBool {
                calledByOwnerBool := eq(sload(0), caller())
            }
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
        }
    }
}
