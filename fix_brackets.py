import re

with open('E:\\Tu vi online\\frontend\\lib\\widgets\\palace_cell.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bad_chunk = """                              const Spacer(flex: 20),
                            ],
                          ),
                        ),
                          ),
                        ),
                    ],
                  ),
                        ),
                      );
                    },
                  ),
                ),
              ),"""

good_chunk = """                              const Spacer(flex: 20),
                            ],
                          ),
                        ),
                    ],
                  ),
                        ),
                      );
                    },
                  ),
                ),
              ),"""

content = content.replace(bad_chunk, good_chunk)

with open('E:\\Tu vi online\\frontend\\lib\\widgets\\palace_cell.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed syntax errors.")
