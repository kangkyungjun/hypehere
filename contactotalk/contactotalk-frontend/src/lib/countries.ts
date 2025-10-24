// ISO 3166-1 alpha-3 국가 코드 목록
export interface Country {
  code: string;
  name: string;
  name_en: string;
}

export const countries: Country[] = [
  { code: 'KOR', name: '대한민국', name_en: 'South Korea' },
  { code: 'USA', name: '미국', name_en: 'United States' },
  { code: 'JPN', name: '일본', name_en: 'Japan' },
  { code: 'CHN', name: '중국', name_en: 'China' },
  { code: 'GBR', name: '영국', name_en: 'United Kingdom' },
  { code: 'FRA', name: '프랑스', name_en: 'France' },
  { code: 'DEU', name: '독일', name_en: 'Germany' },
  { code: 'ITA', name: '이탈리아', name_en: 'Italy' },
  { code: 'ESP', name: '스페인', name_en: 'Spain' },
  { code: 'CAN', name: '캐나다', name_en: 'Canada' },
  { code: 'AUS', name: '호주', name_en: 'Australia' },
  { code: 'BRA', name: '브라질', name_en: 'Brazil' },
  { code: 'MEX', name: '멕시코', name_en: 'Mexico' },
  { code: 'IND', name: '인도', name_en: 'India' },
  { code: 'RUS', name: '러시아', name_en: 'Russia' },
  { code: 'THA', name: '태국', name_en: 'Thailand' },
  { code: 'VNM', name: '베트남', name_en: 'Vietnam' },
  { code: 'IDN', name: '인도네시아', name_en: 'Indonesia' },
  { code: 'MYS', name: '말레이시아', name_en: 'Malaysia' },
  { code: 'SGP', name: '싱가포르', name_en: 'Singapore' },
  { code: 'PHL', name: '필리핀', name_en: 'Philippines' },
  { code: 'NZL', name: '뉴질랜드', name_en: 'New Zealand' },
  { code: 'ARE', name: '아랍에미리트', name_en: 'United Arab Emirates' },
  { code: 'SAU', name: '사우디아라비아', name_en: 'Saudi Arabia' },
  { code: 'TUR', name: '터키', name_en: 'Turkey' },
  { code: 'EGY', name: '이집트', name_en: 'Egypt' },
  { code: 'ZAF', name: '남아프리카공화국', name_en: 'South Africa' },
  { code: 'ARG', name: '아르헨티나', name_en: 'Argentina' },
  { code: 'CHL', name: '칠레', name_en: 'Chile' },
  { code: 'COL', name: '콜롬비아', name_en: 'Colombia' },
  { code: 'PER', name: '페루', name_en: 'Peru' },
  { code: 'POL', name: '폴란드', name_en: 'Poland' },
  { code: 'UKR', name: '우크라이나', name_en: 'Ukraine' },
  { code: 'ROU', name: '루마니아', name_en: 'Romania' },
  { code: 'NLD', name: '네덜란드', name_en: 'Netherlands' },
  { code: 'BEL', name: '벨기에', name_en: 'Belgium' },
  { code: 'GRC', name: '그리스', name_en: 'Greece' },
  { code: 'PRT', name: '포르투갈', name_en: 'Portugal' },
  { code: 'SWE', name: '스웨덴', name_en: 'Sweden' },
  { code: 'NOR', name: '노르웨이', name_en: 'Norway' },
  { code: 'DNK', name: '덴마크', name_en: 'Denmark' },
  { code: 'FIN', name: '핀란드', name_en: 'Finland' },
  { code: 'CHE', name: '스위스', name_en: 'Switzerland' },
  { code: 'AUT', name: '오스트리아', name_en: 'Austria' },
  { code: 'IRL', name: '아일랜드', name_en: 'Ireland' },
  { code: 'CZE', name: '체코', name_en: 'Czech Republic' },
  { code: 'HUN', name: '헝가리', name_en: 'Hungary' },
  { code: 'PAK', name: '파키스탄', name_en: 'Pakistan' },
  { code: 'BGD', name: '방글라데시', name_en: 'Bangladesh' },
  { code: 'LKA', name: '스리랑카', name_en: 'Sri Lanka' },
  { code: 'NPL', name: '네팔', name_en: 'Nepal' },
  { code: 'ISR', name: '이스라엘', name_en: 'Israel' },
  { code: 'IRN', name: '이란', name_en: 'Iran' },
  { code: 'IRQ', name: '이라크', name_en: 'Iraq' },
  { code: 'JOR', name: '요르단', name_en: 'Jordan' },
  { code: 'KWT', name: '쿠웨이트', name_en: 'Kuwait' },
  { code: 'QAT', name: '카타르', name_en: 'Qatar' },
  { code: 'OMN', name: '오만', name_en: 'Oman' },
  { code: 'BHR', name: '바레인', name_en: 'Bahrain' },
  { code: 'LBN', name: '레바논', name_en: 'Lebanon' },
  { code: 'MAR', name: '모로코', name_en: 'Morocco' },
  { code: 'DZA', name: '알제리', name_en: 'Algeria' },
  { code: 'TUN', name: '튀니지', name_en: 'Tunisia' },
  { code: 'LBY', name: '리비아', name_en: 'Libya' },
  { code: 'KEN', name: '케냐', name_en: 'Kenya' },
  { code: 'NGA', name: '나이지리아', name_en: 'Nigeria' },
  { code: 'GHA', name: '가나', name_en: 'Ghana' },
  { code: 'ETH', name: '에티오피아', name_en: 'Ethiopia' },
  { code: 'TZA', name: '탄자니아', name_en: 'Tanzania' },
  { code: 'UGA', name: '우간다', name_en: 'Uganda' },
  { code: 'ZMB', name: '잠비아', name_en: 'Zambia' },
  { code: 'ZWE', name: '짐바브웨', name_en: 'Zimbabwe' },
  { code: 'KAZ', name: '카자흐스탄', name_en: 'Kazakhstan' },
  { code: 'UZB', name: '우즈베키스탄', name_en: 'Uzbekistan' },
  { code: 'MNG', name: '몽골', name_en: 'Mongolia' },
  { code: 'MMR', name: '미얀마', name_en: 'Myanmar' },
  { code: 'KHM', name: '캄보디아', name_en: 'Cambodia' },
  { code: 'LAO', name: '라오스', name_en: 'Laos' },
  { code: 'BGN', name: '부탄', name_en: 'Bhutan' },
  { code: 'MDV', name: '몰디브', name_en: 'Maldives' },
  { code: 'AFG', name: '아프가니스탄', name_en: 'Afghanistan' },
  { code: 'HKG', name: '홍콩', name_en: 'Hong Kong' },
  { code: 'MAC', name: '마카오', name_en: 'Macau' },
  { code: 'TWN', name: '대만', name_en: 'Taiwan' },
  { code: 'PRK', name: '북한', name_en: 'North Korea' },
  { code: 'VEN', name: '베네수엘라', name_en: 'Venezuela' },
  { code: 'CUB', name: '쿠바', name_en: 'Cuba' },
  { code: 'PAN', name: '파나마', name_en: 'Panama' },
  { code: 'CRI', name: '코스타리카', name_en: 'Costa Rica' },
  { code: 'GTM', name: '과테말라', name_en: 'Guatemala' },
  { code: 'ECU', name: '에콰도르', name_en: 'Ecuador' },
  { code: 'BOL', name: '볼리비아', name_en: 'Bolivia' },
  { code: 'PRY', name: '파라과이', name_en: 'Paraguay' },
  { code: 'URY', name: '우루과이', name_en: 'Uruguay' },
  { code: 'DOM', name: '도미니카공화국', name_en: 'Dominican Republic' },
  { code: 'JAM', name: '자메이카', name_en: 'Jamaica' },
  { code: 'TTO', name: '트리니다드 토바고', name_en: 'Trinidad and Tobago' },
  { code: 'SLV', name: '엘살바도르', name_en: 'El Salvador' },
  { code: 'HND', name: '온두라스', name_en: 'Honduras' },
  { code: 'NIC', name: '니카라과', name_en: 'Nicaragua' },
  { code: 'ALB', name: '알바니아', name_en: 'Albania' },
  { code: 'BGR', name: '불가리아', name_en: 'Bulgaria' },
  { code: 'HRV', name: '크로아티아', name_en: 'Croatia' },
  { code: 'SVN', name: '슬로베니아', name_en: 'Slovenia' },
  { code: 'SRB', name: '세르비아', name_en: 'Serbia' },
  { code: 'BIH', name: '보스니아 헤르체고비나', name_en: 'Bosnia and Herzegovina' },
  { code: 'MKD', name: '북마케도니아', name_en: 'North Macedonia' },
  { code: 'MNE', name: '몬테네그로', name_en: 'Montenegro' },
  { code: 'SVK', name: '슬로바키아', name_en: 'Slovakia' },
  { code: 'EST', name: '에스토니아', name_en: 'Estonia' },
  { code: 'LVA', name: '라트비아', name_en: 'Latvia' },
  { code: 'LTU', name: '리투아니아', name_en: 'Lithuania' },
  { code: 'BLR', name: '벨라루스', name_en: 'Belarus' },
  { code: 'MDA', name: '몰도바', name_en: 'Moldova' },
  { code: 'GEO', name: '조지아', name_en: 'Georgia' },
  { code: 'ARM', name: '아르메니아', name_en: 'Armenia' },
  { code: 'AZE', name: '아제르바이잔', name_en: 'Azerbaijan' },
  { code: 'ISL', name: '아이슬란드', name_en: 'Iceland' },
  { code: 'LUX', name: '룩셈부르크', name_en: 'Luxembourg' },
  { code: 'MLT', name: '몰타', name_en: 'Malta' },
  { code: 'CYP', name: '키프로스', name_en: 'Cyprus' },
  { code: 'AND', name: '안도라', name_en: 'Andorra' },
  { code: 'MCO', name: '모나코', name_en: 'Monaco' },
  { code: 'LIE', name: '리히텐슈타인', name_en: 'Liechtenstein' },
  { code: 'SMR', name: '산마리노', name_en: 'San Marino' },
  { code: 'VAT', name: '바티칸', name_en: 'Vatican City' },
  { code: 'SEN', name: '세네갈', name_en: 'Senegal' },
  { code: 'CIV', name: '코트디부아르', name_en: "Côte d'Ivoire" },
  { code: 'CMR', name: '카메룬', name_en: 'Cameroon' },
  { code: 'BEN', name: '베냉', name_en: 'Benin' },
  { code: 'BFA', name: '부르키나파소', name_en: 'Burkina Faso' },
  { code: 'TGO', name: '토고', name_en: 'Togo' },
  { code: 'MLI', name: '말리', name_en: 'Mali' },
  { code: 'NER', name: '니제르', name_en: 'Niger' },
  { code: 'TCD', name: '차드', name_en: 'Chad' },
  { code: 'SOM', name: '소말리아', name_en: 'Somalia' },
  { code: 'SSD', name: '남수단', name_en: 'South Sudan' },
  { code: 'SDN', name: '수단', name_en: 'Sudan' },
  { code: 'ERI', name: '에리트레아', name_en: 'Eritrea' },
  { code: 'DJI', name: '지부티', name_en: 'Djibouti' },
  { code: 'RWA', name: '르완다', name_en: 'Rwanda' },
  { code: 'BDI', name: '부룬디', name_en: 'Burundi' },
  { code: 'MWI', name: '말라위', name_en: 'Malawi' },
  { code: 'MOZ', name: '모잠비크', name_en: 'Mozambique' },
  { code: 'AGO', name: '앙골라', name_en: 'Angola' },
  { code: 'NAM', name: '나미비아', name_en: 'Namibia' },
  { code: 'BWA', name: '보츠와나', name_en: 'Botswana' },
  { code: 'LSO', name: '레소토', name_en: 'Lesotho' },
  { code: 'SWZ', name: '에스와티니', name_en: 'Eswatini' },
  { code: 'MDG', name: '마다가스카르', name_en: 'Madagascar' },
  { code: 'MUS', name: '모리셔스', name_en: 'Mauritius' },
  { code: 'SYC', name: '세이셸', name_en: 'Seychelles' },
  { code: 'COM', name: '코모로', name_en: 'Comoros' },
  { code: 'CPV', name: '카보베르데', name_en: 'Cape Verde' },
  { code: 'GAB', name: '가봉', name_en: 'Gabon' },
  { code: 'GNQ', name: '적도 기니', name_en: 'Equatorial Guinea' },
  { code: 'COG', name: '콩고공화국', name_en: 'Republic of the Congo' },
  { code: 'COD', name: '콩고민주공화국', name_en: 'Democratic Republic of the Congo' },
  { code: 'CAF', name: '중앙아프리카공화국', name_en: 'Central African Republic' },
  { code: 'GIN', name: '기니', name_en: 'Guinea' },
  { code: 'GNB', name: '기니비사우', name_en: 'Guinea-Bissau' },
  { code: 'GMB', name: '감비아', name_en: 'Gambia' },
  { code: 'SLE', name: '시에라리온', name_en: 'Sierra Leone' },
  { code: 'LBR', name: '라이베리아', name_en: 'Liberia' },
  { code: 'MRT', name: '모리타니', name_en: 'Mauritania' },
  { code: 'STP', name: '상투메 프린시페', name_en: 'São Tomé and Príncipe' },
  { code: 'PNG', name: '파푸아뉴기니', name_en: 'Papua New Guinea' },
  { code: 'FJI', name: '피지', name_en: 'Fiji' },
  { code: 'NCL', name: '뉴칼레도니아', name_en: 'New Caledonia' },
  { code: 'PYF', name: '프랑스령 폴리네시아', name_en: 'French Polynesia' },
  { code: 'VUT', name: '바누아투', name_en: 'Vanuatu' },
  { code: 'SLB', name: '솔로몬 제도', name_en: 'Solomon Islands' },
  { code: 'WSM', name: '사모아', name_en: 'Samoa' },
  { code: 'TON', name: '통가', name_en: 'Tonga' },
  { code: 'KIR', name: '키리바시', name_en: 'Kiribati' },
  { code: 'TUV', name: '투발루', name_en: 'Tuvalu' },
  { code: 'PLW', name: '팔라우', name_en: 'Palau' },
  { code: 'FSM', name: '미크로네시아 연방', name_en: 'Micronesia' },
  { code: 'MHL', name: '마셜 제도', name_en: 'Marshall Islands' },
  { code: 'NRU', name: '나우루', name_en: 'Nauru' },
  { code: 'TLS', name: '동티모르', name_en: 'East Timor' },
  { code: 'BRN', name: '브루나이', name_en: 'Brunei' },
];

// SNS Top 20 인기 국가 (사용자 수 기준)
export const popularCountries: string[] = [
  'IND', // 인도 (4.67억)
  'CHN', // 중국 (4.25억)
  'USA', // 미국 (3.02억)
  'IDN', // 인도네시아 (1.90억)
  'BRA', // 브라질 (1.51억)
  'RUS', // 러시아 (1.06억)
  'MEX', // 멕시코 (1.00억)
  'JPN', // 일본 (9,800만)
  'PHL', // 필리핀 (8,900만)
  'VNM', // 베트남 (7,700만)
  'TUR', // 터키 (7,500만)
  'THA', // 태국 (5,700만)
  'GBR', // 영국 (5,300만)
  'FRA', // 프랑스 (5,200만)
  'DEU', // 독일 (5,000만)
  'KOR', // 한국 (4,800만)
  'EGY', // 이집트 (4,500만)
  'ARG', // 아르헨티나 (4,000만)
  'COL', // 콜롬비아 (3,900만)
  'ESP', // 스페인 (3,800만)
];

// 인기 국가를 상단에 배치한 정렬된 리스트
export const sortedCountries: Country[] = [
  ...countries.filter((c) => popularCountries.includes(c.code)),
  ...countries.filter((c) => !popularCountries.includes(c.code)),
];

// 인기 국가 여부 확인
export const isPopularCountry = (code: string): boolean => {
  return popularCountries.includes(code);
};

// 드롭다운 등에서 사용할 국가 목록 반환 (인기 국가 우선)
export const getCountriesForDisplay = (): Country[] => {
  return sortedCountries;
};

export const getCountryName = (code: string): string => {
  const country = countries.find((c) => c.code === code);
  return country ? country.name : code;
};

export const getCountryNameEn = (code: string): string => {
  const country = countries.find((c) => c.code === code);
  return country ? country.name_en : code;
};
