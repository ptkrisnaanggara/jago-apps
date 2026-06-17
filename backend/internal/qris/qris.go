// Package qris parses QRIS (EMVCo merchant QR) payloads. It reads the
// top-level TLV fields we need: merchant name (59), city (60) and the
// transaction amount (54, present only on "dynamic"/amount-embedded QRs).
package qris

import (
	"math"
	"strconv"
)

// Info is the decoded QRIS content.
type Info struct {
	MerchantName string `json:"merchantName"`
	MerchantCity string `json:"merchantCity"`
	Amount       int64  `json:"amount"`  // 0 when not embedded
	Dynamic      bool   `json:"dynamic"` // true when the QR carries an amount
}

// Parse scans the top-level EMV TLV structure. Unknown/garbage input yields a
// generic merchant with no amount (the caller then asks the user for one).
func Parse(payload string) Info {
	info := Info{}
	for i := 0; i+4 <= len(payload); {
		id := payload[i : i+2]
		length, err := strconv.Atoi(payload[i+2 : i+4])
		if err != nil || i+4+length > len(payload) {
			break
		}
		value := payload[i+4 : i+4+length]
		i += 4 + length

		switch id {
		case "54": // transaction amount
			if f, err := strconv.ParseFloat(value, 64); err == nil {
				info.Amount = int64(math.Round(f))
				info.Dynamic = true
			}
		case "59": // merchant name
			info.MerchantName = value
		case "60": // merchant city
			info.MerchantCity = value
		}
	}
	if info.MerchantName == "" {
		info.MerchantName = "QRIS Merchant"
	}
	return info
}
