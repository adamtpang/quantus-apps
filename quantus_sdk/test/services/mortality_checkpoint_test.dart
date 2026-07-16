import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

void main() {
  group('SubstrateService.fetchMortalityCheckpoint', () {
    test('returns the hash at the header block number even when the chain advances between calls', () async {
      // Block 100 is best when the header is read; block 101 lands immediately
      // after. The old implementation fetched the *best* hash in a separate
      // call and could pair block 100's number with block 101's hash, which
      // makes the node reject the mortal extrinsic's signature.
      const hashes = {100: '0xaaaa', 101: '0xbbbb'};
      var bestNumber = 100;

      Future<dynamic> rpc(String method, List<dynamic> params) async {
        switch (method) {
          case 'chain_getHeader':
            final header = {'number': '0x${bestNumber.toRadixString(16)}'};
            bestNumber = 101;
            return header;
          case 'chain_getBlockHash':
            final number = params.isEmpty ? bestNumber : params.first as int;
            return hashes[number];
          default:
            throw UnsupportedError(method);
        }
      }

      final checkpoint = await SubstrateService.fetchMortalityCheckpoint(rpc);

      expect(checkpoint.blockNumber, 100);
      expect(checkpoint.blockHash, 'aaaa');
    });

    test('throws when the node cannot resolve the hash for the birth block', () async {
      Future<dynamic> rpc(String method, List<dynamic> params) async {
        if (method == 'chain_getHeader') return {'number': '0x64'};
        return null;
      }

      expect(SubstrateService.fetchMortalityCheckpoint(rpc), throwsException);
    });
  });
}
