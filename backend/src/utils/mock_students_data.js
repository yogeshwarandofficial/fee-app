const mockStudents = [
  // ── GRADE 1 ──────────────────────────────────────────────
  {
    "full_name": "Aarav K",
    "phone_number": "9876540101",
    "gradeName": "1",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Aarav+K&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 10000, "due": 5000 }, "transport": { "paid": 2000, "due": 0 }, "other": { "paid": 500, "due": 0 } }
  },
  {
    "full_name": "Dhivya M",
    "phone_number": "9876540102",
    "gradeName": "1",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Dhivya+M&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 15000, "due": 0 }, "transport": { "paid": 1500, "due": 500 }, "other": { "paid": 500, "due": 0 } }
  },
  {
    "full_name": "Karthik R",
    "phone_number": "9876540103",
    "gradeName": "1",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Karthik+R&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 5000, "due": 10000 }, "transport": { "paid": 0, "due": 2000 }, "other": { "paid": 0, "due": 500 } }
  },
  {
    "full_name": "Sruthi S",
    "phone_number": "9876540104",
    "gradeName": "1",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Sruthi+S&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 15000, "due": 0 }, "transport": { "paid": 2000, "due": 0 }, "other": { "paid": 500, "due": 0 } }
  },
  {
    "full_name": "Vignesh T",
    "phone_number": "9876540105",
    "gradeName": "1",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Vignesh+T&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 8000, "due": 7000 }, "transport": { "paid": 1000, "due": 1000 }, "other": { "paid": 250, "due": 250 } }
  },
  {
    "full_name": "Anitha P",
    "phone_number": "9876540106",
    "gradeName": "1",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Anitha+P&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 15000, "due": 0 }, "transport": { "paid": 0, "due": 2000 }, "other": { "paid": 500, "due": 0 } }
  },

  // ── GRADE 2 ──────────────────────────────────────────────
  {
    "full_name": "Gokul N",
    "phone_number": "9876540201",
    "gradeName": "2",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Gokul+N&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 16000, "due": 0 }, "transport": { "paid": 2500, "due": 0 }, "other": { "paid": 600, "due": 0 } }
  },
  {
    "full_name": "Meenakshi V",
    "phone_number": "9876540202",
    "gradeName": "2",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Meenakshi+V&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 10000, "due": 6000 }, "transport": { "paid": 1500, "due": 1000 }, "other": { "paid": 600, "due": 0 } }
  },
  {
    "full_name": "Surya B",
    "phone_number": "9876540203",
    "gradeName": "2",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Surya+B&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 0, "due": 16000 }, "transport": { "paid": 0, "due": 2500 }, "other": { "paid": 0, "due": 600 } }
  },
  {
    "full_name": "Nithya C",
    "phone_number": "9876540204",
    "gradeName": "2",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Nithya+C&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 16000, "due": 0 }, "transport": { "paid": 2500, "due": 0 }, "other": { "paid": 600, "due": 0 } }
  },
  {
    "full_name": "Ashwin D",
    "phone_number": "9876540205",
    "gradeName": "2",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Ashwin+D&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 12000, "due": 4000 }, "transport": { "paid": 2000, "due": 500 }, "other": { "paid": 300, "due": 300 } }
  },
  {
    "full_name": "Kavya L",
    "phone_number": "9876540206",
    "gradeName": "2",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Kavya+L&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 15500, "due": 500 }, "transport": { "paid": 2500, "due": 0 }, "other": { "paid": 600, "due": 0 } }
  },

  // ── GRADE 3 ──────────────────────────────────────────────
  {
    "full_name": "Praveen J",
    "phone_number": "9876540301",
    "gradeName": "3",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Praveen+J&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 17000, "due": 0 }, "transport": { "paid": 2500, "due": 0 }, "other": { "paid": 700, "due": 0 } }
  },
  {
    "full_name": "Sneha K",
    "phone_number": "9876540302",
    "gradeName": "3",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Sneha+K&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 8500, "due": 8500 }, "transport": { "paid": 1250, "due": 1250 }, "other": { "paid": 350, "due": 350 } }
  },
  {
    "full_name": "Arun M",
    "phone_number": "9876540303",
    "gradeName": "3",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Arun+M&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 5000, "due": 12000 }, "transport": { "paid": 500, "due": 2000 }, "other": { "paid": 700, "due": 0 } }
  },
  {
    "full_name": "Priyanka R",
    "phone_number": "9876540304",
    "gradeName": "3",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Priyanka+R&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 17000, "due": 0 }, "transport": { "paid": 2500, "due": 0 }, "other": { "paid": 700, "due": 0 } }
  },
  {
    "full_name": "Dinesh S",
    "phone_number": "9876540305",
    "gradeName": "3",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Dinesh+S&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 16000, "due": 1000 }, "transport": { "paid": 2500, "due": 0 }, "other": { "paid": 0, "due": 700 } }
  },
  {
    "full_name": "Swathi V",
    "phone_number": "9876540306",
    "gradeName": "3",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Swathi+V&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 10000, "due": 7000 }, "transport": { "paid": 2000, "due": 500 }, "other": { "paid": 700, "due": 0 } }
  },

  // ── GRADE 4 ──────────────────────────────────────────────
  {
    "full_name": "Manoj P",
    "phone_number": "9876540401",
    "gradeName": "4",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Manoj+P&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 18000, "due": 0 }, "transport": { "paid": 3000, "due": 0 }, "other": { "paid": 800, "due": 0 } }
  },
  {
    "full_name": "Deepa T",
    "phone_number": "9876540402",
    "gradeName": "4",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Deepa+T&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 9000, "due": 9000 }, "transport": { "paid": 1500, "due": 1500 }, "other": { "paid": 400, "due": 400 } }
  },
  {
    "full_name": "Hari N",
    "phone_number": "9876540403",
    "gradeName": "4",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Hari+N&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 0, "due": 18000 }, "transport": { "paid": 0, "due": 3000 }, "other": { "paid": 800, "due": 0 } }
  },
  {
    "full_name": "Preethi L",
    "phone_number": "9876540404",
    "gradeName": "4",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Preethi+L&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 18000, "due": 0 }, "transport": { "paid": 3000, "due": 0 }, "other": { "paid": 800, "due": 0 } }
  },
  {
    "full_name": "Sanjay B",
    "phone_number": "9876540405",
    "gradeName": "4",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Sanjay+B&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 15000, "due": 3000 }, "transport": { "paid": 3000, "due": 0 }, "other": { "paid": 500, "due": 300 } }
  },
  {
    "full_name": "Nandhini C",
    "phone_number": "9876540406",
    "gradeName": "4",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Nandhini+C&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 5000, "due": 13000 }, "transport": { "paid": 1000, "due": 2000 }, "other": { "paid": 0, "due": 800 } }
  },

  // ── GRADE 5 ──────────────────────────────────────────────
  {
    "full_name": "Kamal R",
    "phone_number": "9876540501",
    "gradeName": "5",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Kamal+R&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 19000, "due": 0 }, "transport": { "paid": 3200, "due": 0 }, "other": { "paid": 900, "due": 0 } }
  },
  {
    "full_name": "Roopa S",
    "phone_number": "9876540502",
    "gradeName": "5",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Roopa+S&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 10000, "due": 9000 }, "transport": { "paid": 1600, "due": 1600 }, "other": { "paid": 900, "due": 0 } }
  },
  {
    "full_name": "Prabhu M",
    "phone_number": "9876540503",
    "gradeName": "5",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Prabhu+M&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 4000, "due": 15000 }, "transport": { "paid": 0, "due": 3200 }, "other": { "paid": 0, "due": 900 } }
  },
  {
    "full_name": "Anand D",
    "phone_number": "9876540504",
    "gradeName": "5",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Anand+D&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 19000, "due": 0 }, "transport": { "paid": 3200, "due": 0 }, "other": { "paid": 900, "due": 0 } }
  },
  {
    "full_name": "Sowmya K",
    "phone_number": "9876540505",
    "gradeName": "5",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Sowmya+K&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 18500, "due": 500 }, "transport": { "paid": 3000, "due": 200 }, "other": { "paid": 900, "due": 0 } }
  },
  {
    "full_name": "Balaji V",
    "phone_number": "9876540506",
    "gradeName": "5",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Balaji+V&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 10000, "due": 9000 }, "transport": { "paid": 3200, "due": 0 }, "other": { "paid": 450, "due": 450 } }
  },

  // ── GRADE 6 ──────────────────────────────────────────────
  {
    "full_name": "Ramesh P",
    "phone_number": "9876540601",
    "gradeName": "6",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Ramesh+P&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 20000, "due": 0 }, "transport": { "paid": 3500, "due": 0 }, "other": { "paid": 1000, "due": 0 } }
  },
  {
    "full_name": "Geetha N",
    "phone_number": "9876540602",
    "gradeName": "6",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Geetha+N&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 10000, "due": 10000 }, "transport": { "paid": 1750, "due": 1750 }, "other": { "paid": 500, "due": 500 } }
  },
  {
    "full_name": "Venkatesh T",
    "phone_number": "9876540603",
    "gradeName": "6",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Venkatesh+T&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 0, "due": 20000 }, "transport": { "paid": 0, "due": 3500 }, "other": { "paid": 1000, "due": 0 } }
  },
  {
    "full_name": "Aarthi L",
    "phone_number": "9876540604",
    "gradeName": "6",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Aarthi+L&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 20000, "due": 0 }, "transport": { "paid": 3500, "due": 0 }, "other": { "paid": 1000, "due": 0 } }
  },
  {
    "full_name": "Murali C",
    "phone_number": "9876540605",
    "gradeName": "6",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Murali+C&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 15000, "due": 5000 }, "transport": { "paid": 3500, "due": 0 }, "other": { "paid": 0, "due": 1000 } }
  },
  {
    "full_name": "Keerthi B",
    "phone_number": "9876540606",
    "gradeName": "6",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Keerthi+B&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 5000, "due": 15000 }, "transport": { "paid": 1000, "due": 2500 }, "other": { "paid": 500, "due": 500 } }
  },

  // ── GRADE 7 ──────────────────────────────────────────────
  {
    "full_name": "Rajesh S",
    "phone_number": "9876540701",
    "gradeName": "7",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Rajesh+S&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 21000, "due": 0 }, "transport": { "paid": 4000, "due": 0 }, "other": { "paid": 1100, "due": 0 } }
  },
  {
    "full_name": "Nithish R",
    "phone_number": "9876540702",
    "gradeName": "7",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Nithish+R&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 11000, "due": 10000 }, "transport": { "paid": 2000, "due": 2000 }, "other": { "paid": 1100, "due": 0 } }
  },
  {
    "full_name": "Sindhu M",
    "phone_number": "9876540703",
    "gradeName": "7",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Sindhu+M&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 5000, "due": 16000 }, "transport": { "paid": 1000, "due": 3000 }, "other": { "paid": 0, "due": 1100 } }
  },
  {
    "full_name": "Siva N",
    "phone_number": "9876540704",
    "gradeName": "7",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Siva+N&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 21000, "due": 0 }, "transport": { "paid": 4000, "due": 0 }, "other": { "paid": 1100, "due": 0 } }
  },
  {
    "full_name": "Pavithra K",
    "phone_number": "9876540705",
    "gradeName": "7",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Pavithra+K&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 20000, "due": 1000 }, "transport": { "paid": 4000, "due": 0 }, "other": { "paid": 550, "due": 550 } }
  },
  {
    "full_name": "Ganesh V",
    "phone_number": "9876540706",
    "gradeName": "7",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Ganesh+V&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 0, "due": 21000 }, "transport": { "paid": 0, "due": 4000 }, "other": { "paid": 0, "due": 1100 } }
  },

  // ── GRADE 8 ──────────────────────────────────────────────
  {
    "full_name": "Mohan P",
    "phone_number": "9876540801",
    "gradeName": "8",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Mohan+P&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 22000, "due": 0 }, "transport": { "paid": 4500, "due": 0 }, "other": { "paid": 1200, "due": 0 } }
  },
  {
    "full_name": "Vidya T",
    "phone_number": "9876540802",
    "gradeName": "8",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Vidya+T&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 11000, "due": 11000 }, "transport": { "paid": 2250, "due": 2250 }, "other": { "paid": 600, "due": 600 } }
  },
  {
    "full_name": "Saravanan L",
    "phone_number": "9876540803",
    "gradeName": "8",
    "sectionName": "A",
    "avatar_url": "https://ui-avatars.com/api/?name=Saravanan+L&background=random",
    "routeName": "Hasthampatti",
    "balances": { "tuition": { "paid": 0, "due": 22000 }, "transport": { "paid": 500, "due": 4000 }, "other": { "paid": 1200, "due": 0 } }
  },
  {
    "full_name": "Lakshmi C",
    "phone_number": "9876540804",
    "gradeName": "8",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Lakshmi+C&background=random",
    "routeName": "Ammapet",
    "balances": { "tuition": { "paid": 22000, "due": 0 }, "transport": { "paid": 4500, "due": 0 }, "other": { "paid": 1200, "due": 0 } }
  },
  {
    "full_name": "Prakash B",
    "phone_number": "9876540805",
    "gradeName": "8",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Prakash+B&background=random",
    "routeName": "Suramangalam",
    "balances": { "tuition": { "paid": 16000, "due": 6000 }, "transport": { "paid": 4500, "due": 0 }, "other": { "paid": 0, "due": 1200 } }
  },
  {
    "full_name": "Ramya D",
    "phone_number": "9876540806",
    "gradeName": "8",
    "sectionName": "B",
    "avatar_url": "https://ui-avatars.com/api/?name=Ramya+D&background=random",
    "routeName": "Alagapuram",
    "balances": { "tuition": { "paid": 18000, "due": 4000 }, "transport": { "paid": 2000, "due": 2500 }, "other": { "paid": 1200, "due": 0 } }
  }
];
module.exports = mockStudents;