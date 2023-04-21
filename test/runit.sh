#!/bin/bash -e

test_ping() {
  CONTAINER=$1
  shift
  REMOTES="$@"
  for r in $REMOTES; do
    if docker exec "$CONTAINER" /bin/bash -c "ping -i .1 -c 3 $r -q || echo 'NoPing'" | grep -q NoPing; then
      echo "Ping failed from $CONTAINER to $r"
      exit 1
    fi
    echo "Ping OK from $CONTAINER to $r"
  done
}

test_vpn() {
  VPN=$1
  echo "*** Starting test for $VPN"
  RUN=$VPN docker-compose up -d
  sleep 5

  test_ping MainS 10.0.2.2 10.0.2.10 10.0.2.11
  test_ping MainC1 10.0.2.2 10.0.2.10 10.0.2.11
  test_ping MainC2 10.0.2.2 10.0.2.10 10.0.2.11
  test_ping FarS 10.0.1.2 10.0.1.10 10.0.1.11
  test_ping FarC1 10.0.1.2 10.0.1.10 10.0.1.11
  test_ping FarC2 10.0.1.2 10.0.1.10 10.0.1.11
  test_ping Remote 10.0.1.2 10.0.1.10 10.0.1.11 10.0.2.2 10.0.2.10 10.0.2.11
  docker-compose down
}

cleanup() {
  docker-compose down
}

trap cleanup EXIT

TESTS=${1:-openvpn wireguard ipsec}

cleanup
for t in $TESTS; do
  test_vpn "$t.sh"
done
