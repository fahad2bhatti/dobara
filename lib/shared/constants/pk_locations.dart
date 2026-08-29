/// Pakistan province/city reference data, shared by any screen that
/// collects a delivery address (Checkout, Manage Addresses). Kept in
/// one place so the two never drift out of sync.
const List<String> kProvinces = [
  'Punjab',
  'Sindh',
  'Khyber Pakhtunkhwa',
  'Balochistan',
  'Islamabad',
  'Gilgit-Baltistan',
  'Azad Kashmir',
];

const Map<String, List<String>> kCitiesByProvince = {
  'Punjab': [
    'Lahore', 'Faisalabad', 'Rawalpindi', 'Multan', 'Gujranwala',
    'Sialkot', 'Bahawalpur', 'Sargodha', 'Sheikhupura', 'Rahim Yar Khan',
    'Gujrat', 'Jhelum',
  ],
  'Sindh': [
    'Karachi', 'Hyderabad', 'Sukkur', 'Larkana', 'Nawabshah', 'Mirpur Khas',
  ],
  'Khyber Pakhtunkhwa': [
    'Peshawar', 'Abbottabad', 'Mardan', 'Swat', 'Kohat', 'Bannu', 'Mingora',
  ],
  'Balochistan': [
    'Quetta', 'Gwadar', 'Turbat', 'Khuzdar', 'Sibi',
  ],
  'Islamabad': ['Islamabad'],
  'Gilgit-Baltistan': ['Gilgit', 'Skardu', 'Hunza'],
  'Azad Kashmir': ['Muzaffarabad', 'Mirpur', 'Rawalakot'],
};

const List<String> kAddressLabels = ['Home', 'Office', 'Other'];
