from python import Python

fn send_raw_transaction(raw_tx: List[Int]) raises -> String:
    var tx_hex = "0x"
    for b in raw_tx:
        var high = b // 16
        var low = b % 16
        if high < 10:
            tx_hex += chr(ord('0') + high)
        else:
            tx_hex += chr(ord('a') + high - 10)
        if low < 10:
            tx_hex += chr(ord('0') + low)
        else:
            tx_hex += chr(ord('a') + low - 10)

    var payload_obj = Python.dict()
    payload_obj["jsonrpc"] = "2.0"
    payload_obj["method"] = "eth_sendRawTransaction"
    var params_list = Python.list()
    params_list.append(tx_hex)
    payload_obj["params"] = params_list
    payload_obj["id"] = 1

    var json = Python.import_module("json")
    var payload_str_py = json.dumps(payload_obj)
    var payload_str = String(payload_str_py)

    var socket = Python.import_module("socket")
    var HOST = "127.0.0.1"
    var PORT = 8545

    var builtins = Python.import_module("builtins")
    var address_tuple = builtins.tuple([Python.str(HOST), PORT])

    var s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(address_tuple)

    var request = "POST / HTTP/1.1\r\n"
    request += "Host: 127.0.0.1:8545\r\n"
    request += "Content-Type: application/json\r\n"
    request += "Content-Length: " + String(len(payload_str)) + "\r\n"
    request += "Connection: close\r\n"
    request += "\r\n"
    request += payload_str

    s.sendall(Python.str(request).encode("utf-8"))

    var response_bytes = s.recv(4096)
    var response_py_str = response_bytes.decode("utf-8")
    var response_str = String(response_py_str)

    var http_end = "\r\n\r\n"
    var maybe_json_start = response_str.find(http_end)
    if maybe_json_start != -1:
        var json_start = maybe_json_start + len(http_end)
        return response_str[json_start:]

    return response_str
