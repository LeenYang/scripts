from scapy.all import *
import argparse

def main():
    # Create ArgumentParser object
    parser = argparse.ArgumentParser(description="Add Ethernet header to a PCAP")

    # Add positional arguments
    parser.add_argument("in_pcap", type=str, help="The PCAP file as input")
    parser.add_argument("out_pcap", type=str, help="The PCAP file as output")

    # Parse the command-line arguments
    args = parser.parse_args()

    # Access the parsed arguments
    input_pcap = args.in_pcap
    output_pcap = args.out_pcap

    # Print the parsed arguments
    print("Adding Eth header to %s and write it to %s" % (input_pcap, output_pcap))

    # Source and destination MAC addresses
    src_mac = "00:11:22:33:44:55"
    dest_mac = "66:77:88:99:aa:bb"


    # Read input pcap file
    packets = rdpcap(input_pcap)
    fst_src_ip = None
    # Write to the output
    with PcapWriter(output_pcap) as pcap:
        # Add Ethernet headers to each packet
        for pkt in packets:
            if fst_src_ip is None and pkt[IP] is not None:
                fst_src_ip =  pkt[IP].src
            # Construct Ethernet header
            eth_header = Ether(src=src_mac, dst=dest_mac) if pkt[IP].src == fst_src_ip else Ether(src=dest_mac, dst=src_mac)
            ip_header = pkt[IP]
            tcp_header = pkt[TCP]
            pkt_new = eth_header / ip_header # / tcp_header
            pcap.write(pkt_new)
        print('Done.')
if __name__ == "__main__":
    main()
