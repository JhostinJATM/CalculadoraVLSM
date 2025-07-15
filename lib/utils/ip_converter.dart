class IPConverter {
  static String ipToBinary(String ip) {
    return ip.split('.').map((part) {
      return int.parse(part).toRadixString(2).padLeft(8, '0');
    }).join('.');
  }

  static final prefixData = [
    {'prefix': '/32', 'hosts': '1', 'mask': '255.255.255.255'},
    {'prefix': '/31', 'hosts': '2', 'mask': '255.255.255.254'},
    {'prefix': '/30', 'hosts': '2', 'mask': '255.255.255.252'},
    {'prefix': '/29', 'hosts': '6', 'mask': '255.255.255.248'},
    {'prefix': '/28', 'hosts': '14', 'mask': '255.255.255.240'},
    {'prefix': '/27', 'hosts': '30', 'mask': '255.255.255.224'},
    {'prefix': '/26', 'hosts': '62', 'mask': '255.255.255.192'},
    {'prefix': '/25', 'hosts': '126', 'mask': '255.255.255.128'},
    {'prefix': '/24', 'hosts': '254', 'mask': '255.255.255.0'},
    {'prefix': '/23', 'hosts': '510', 'mask': '255.255.254.0'},
    {'prefix': '/22', 'hosts': '1022', 'mask': '255.255.252.0'},
    {'prefix': '/21', 'hosts': '2046', 'mask': '255.255.248.0'},
    {'prefix': '/20', 'hosts': '4094', 'mask': '255.255.240.0'},
  ];
}