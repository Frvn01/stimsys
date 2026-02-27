import 'question_model.dart';

class AssessmentData {
  static List<Assessment> getAssessmentsForSubject(String subjectName) {
    switch (subjectName) {
      case 'Application Development and Emerging Technologies':
        return _adetAssessments;
      case 'Database Management Systems 2':
        return _dbmsAssessments;
      case 'Information Assurance Security 2':
        return _iasAssessments;
      default:
        return _defaultAssessments(subjectName);
    }
  }

  static List<String> get terms =>
      ['Prelims', 'Midterms', 'Pre-Finals', 'Finals'];

  // ─── ADET ────────────────────────────────────────────────────────────────

  static final List<Assessment> _adetAssessments = [
    // PRELIMS QUIZ
    Assessment(
      id: 'adet_prelims_quiz',
      subjectName: 'Application Development and Emerging Technologies',
      term: 'Prelims',
      type: 'Quiz',
      questions: [
        Question(
          id: 'q1',
          text: 'What does Flutter use as its primary programming language?',
          type: QuestionType.multipleChoice,
          choices: ['Java', 'Kotlin', 'Dart', 'Swift'],
          correctAnswer: 'Dart',
        ),
        Question(
          id: 'q2',
          text: 'What is the name of the widget used for scrollable lists in Flutter?',
          type: QuestionType.multipleChoice,
          choices: ['ScrollView', 'ListView', 'RecyclerView', 'ScrollWidget'],
          correctAnswer: 'ListView',
        ),
        Question(
          id: 'q3',
          text: 'Name the command to create a new Flutter project.',
          type: QuestionType.identification,
          correctAnswer: 'flutter create',
        ),
        Question(
          id: 'q4',
          text: 'What does API stand for?',
          type: QuestionType.identification,
          correctAnswer: 'Application Programming Interface',
        ),
        Question(
          id: 'q5',
          text: 'List 3 types of mobile app development approaches.',
          type: QuestionType.enumeration,
          correctAnswer: 'Native',
          enumerationAnswers: ['Native', 'Hybrid', 'Cross-platform'],
        ),
      ],
    ),
    // PRELIMS EXAM
    Assessment(
      id: 'adet_prelims_exam',
      subjectName: 'Application Development and Emerging Technologies',
      term: 'Prelims',
      type: 'Exam',
      questions: [
        Question(
          id: 'e1',
          text: 'Which company developed Flutter?',
          type: QuestionType.multipleChoice,
          choices: ['Apple', 'Microsoft', 'Google', 'Meta'],
          correctAnswer: 'Google',
        ),
        Question(
          id: 'e2',
          text: 'What is hot reload in Flutter?',
          type: QuestionType.multipleChoice,
          choices: [
            'Restarting the app completely',
            'Updating UI without losing state',
            'Clearing the cache',
            'Rebuilding all widgets',
          ],
          correctAnswer: 'Updating UI without losing state',
        ),
        Question(
          id: 'e3',
          text:
              'What widget is the root of every Flutter app that uses Material Design?',
          type: QuestionType.identification,
          correctAnswer: 'MaterialApp',
        ),
        Question(
          id: 'e4',
          text: 'Name the emerging technology that enables running ML models on-device.',
          type: QuestionType.identification,
          correctAnswer: 'Edge AI',
        ),
        Question(
          id: 'e5',
          text: 'List 3 key features of emerging technologies in mobile apps.',
          type: QuestionType.enumeration,
          correctAnswer: 'AI',
          enumerationAnswers: ['AI', 'AR', 'IoT'],
        ),
      ],
    ),
    // MIDTERMS QUIZ
    Assessment(
      id: 'adet_midterms_quiz',
      subjectName: 'Application Development and Emerging Technologies',
      term: 'Midterms',
      type: 'Quiz',
      questions: [
        Question(
          id: 'mq1',
          text: 'What is state management in Flutter?',
          type: QuestionType.multipleChoice,
          choices: [
            'Managing app storage',
            'Controlling how data flows and updates UI',
            'Handling network requests',
            'Managing user authentication',
          ],
          correctAnswer: 'Controlling how data flows and updates UI',
        ),
        Question(
          id: 'mq2',
          text: 'Which of these is NOT a state management solution in Flutter?',
          type: QuestionType.multipleChoice,
          choices: ['Provider', 'Riverpod', 'Redux', 'SpringBoot'],
          correctAnswer: 'SpringBoot',
        ),
        Question(
          id: 'mq3',
          text: 'What method is called when a StatefulWidget is first built?',
          type: QuestionType.identification,
          correctAnswer: 'initState',
        ),
        Question(
          id: 'mq4',
          text: 'Name the Flutter widget that handles user gestures.',
          type: QuestionType.identification,
          correctAnswer: 'GestureDetector',
        ),
        Question(
          id: 'mq5',
          text: 'List 3 types of layout widgets in Flutter.',
          type: QuestionType.enumeration,
          correctAnswer: 'Row',
          enumerationAnswers: ['Row', 'Column', 'Stack'],
        ),
      ],
    ),
    // MIDTERMS EXAM
    Assessment(
      id: 'adet_midterms_exam',
      subjectName: 'Application Development and Emerging Technologies',
      term: 'Midterms',
      type: 'Exam',
      questions: [
        Question(
          id: 'me1',
          text: 'Which pattern does Provider use?',
          type: QuestionType.multipleChoice,
          choices: ['MVC', 'Observer', 'Singleton', 'Factory'],
          correctAnswer: 'Observer',
        ),
        Question(
          id: 'me2',
          text: 'What is the purpose of BuildContext in Flutter?',
          type: QuestionType.multipleChoice,
          choices: [
            'To store app data',
            'To locate a widget in the widget tree',
            'To handle animations',
            'To manage routes',
          ],
          correctAnswer: 'To locate a widget in the widget tree',
        ),
        Question(
          id: 'me3',
          text: 'What keyword is used to call an async function and wait for result?',
          type: QuestionType.identification,
          correctAnswer: 'await',
        ),
        Question(
          id: 'me4',
          text: 'Name the widget used to display images from the internet.',
          type: QuestionType.identification,
          correctAnswer: 'Image.network',
        ),
        Question(
          id: 'me5',
          text: 'List 3 navigation methods available in Flutter.',
          type: QuestionType.enumeration,
          correctAnswer: 'push',
          enumerationAnswers: ['push', 'pop', 'pushReplacement'],
        ),
      ],
    ),
    // PRE-FINALS QUIZ
    Assessment(
      id: 'adet_prefinals_quiz',
      subjectName: 'Application Development and Emerging Technologies',
      term: 'Pre-Finals',
      type: 'Quiz',
      questions: [
        Question(
          id: 'pfq1',
          text: 'What is Firebase primarily used for in mobile apps?',
          type: QuestionType.multipleChoice,
          choices: [
            'UI design',
            'Backend services and real-time database',
            'Code compilation',
            'Testing',
          ],
          correctAnswer: 'Backend services and real-time database',
        ),
        Question(
          id: 'pfq2',
          text: 'Which Firebase service handles user authentication?',
          type: QuestionType.multipleChoice,
          choices: [
            'Firestore',
            'Firebase Auth',
            'Firebase Storage',
            'Firebase Functions',
          ],
          correctAnswer: 'Firebase Auth',
        ),
        Question(
          id: 'pfq3',
          text: 'What format does Firestore use to store documents?',
          type: QuestionType.identification,
          correctAnswer: 'JSON',
        ),
        Question(
          id: 'pfq4',
          text: 'Name the tool used to test REST APIs.',
          type: QuestionType.identification,
          correctAnswer: 'Postman',
        ),
        Question(
          id: 'pfq5',
          text: 'List 3 Firebase services used in app development.',
          type: QuestionType.enumeration,
          correctAnswer: 'Authentication',
          enumerationAnswers: ['Authentication', 'Firestore', 'Storage'],
        ),
      ],
    ),
    // PRE-FINALS EXAM
    Assessment(
      id: 'adet_prefinals_exam',
      subjectName: 'Application Development and Emerging Technologies',
      term: 'Pre-Finals',
      type: 'Exam',
      questions: [
        Question(
          id: 'pfe1',
          text: 'What does REST stand for?',
          type: QuestionType.multipleChoice,
          choices: [
            'Remote Execution State Transfer',
            'Representational State Transfer',
            'Reduced State Technology',
            'Remote System Transfer',
          ],
          correctAnswer: 'Representational State Transfer',
        ),
        Question(
          id: 'pfe2',
          text: 'Which HTTP method is used to retrieve data?',
          type: QuestionType.multipleChoice,
          choices: ['POST', 'PUT', 'GET', 'DELETE'],
          correctAnswer: 'GET',
        ),
        Question(
          id: 'pfe3',
          text: 'What class in Dart is used to make HTTP requests?',
          type: QuestionType.identification,
          correctAnswer: 'http.Client',
        ),
        Question(
          id: 'pfe4',
          text: 'Name the process of converting JSON to a Dart object.',
          type: QuestionType.identification,
          correctAnswer: 'Deserialization',
        ),
        Question(
          id: 'pfe5',
          text: 'List 3 HTTP status codes and their meanings.',
          type: QuestionType.enumeration,
          correctAnswer: '200',
          enumerationAnswers: ['200', '404', '500'],
        ),
      ],
    ),
    // FINALS QUIZ
    Assessment(
      id: 'adet_finals_quiz',
      subjectName: 'Application Development and Emerging Technologies',
      term: 'Finals',
      type: 'Quiz',
      questions: [
        Question(
          id: 'fq1',
          text: 'What is the purpose of a splash screen?',
          type: QuestionType.multipleChoice,
          choices: [
            'To show advertisements',
            'To initialize the app while showing branding',
            'To handle authentication',
            'To display error messages',
          ],
          correctAnswer: 'To initialize the app while showing branding',
        ),
        Question(
          id: 'fq2',
          text: 'Which package is commonly used for local data persistence in Flutter?',
          type: QuestionType.multipleChoice,
          choices: ['sqflite', 'firebase', 'hive', 'Both sqflite and hive'],
          correctAnswer: 'Both sqflite and hive',
        ),
        Question(
          id: 'fq3',
          text: 'What is the purpose of the pubspec.yaml file?',
          type: QuestionType.identification,
          correctAnswer: 'Managing dependencies and assets',
        ),
        Question(
          id: 'fq4',
          text: 'Name the process of releasing an app to the Play Store.',
          type: QuestionType.identification,
          correctAnswer: 'App deployment',
        ),
        Question(
          id: 'fq5',
          text: 'List 3 best practices in mobile app UI/UX design.',
          type: QuestionType.enumeration,
          correctAnswer: 'Consistency',
          enumerationAnswers: ['Consistency', 'Accessibility', 'Responsiveness'],
        ),
      ],
    ),
    // FINALS EXAM
    Assessment(
      id: 'adet_finals_exam',
      subjectName: 'Application Development and Emerging Technologies',
      term: 'Finals',
      type: 'Exam',
      questions: [
        Question(
          id: 'fe1',
          text: 'What is CI/CD in app development?',
          type: QuestionType.multipleChoice,
          choices: [
            'Code Integration / Code Deployment',
            'Continuous Integration / Continuous Delivery',
            'Client Interface / Client Design',
            'Core Integration / Core Deployment',
          ],
          correctAnswer: 'Continuous Integration / Continuous Delivery',
        ),
        Question(
          id: 'fe2',
          text: 'Which tool is used for Flutter app testing?',
          type: QuestionType.multipleChoice,
          choices: ['JUnit', 'Flutter Test', 'Espresso', 'XCTest'],
          correctAnswer: 'Flutter Test',
        ),
        Question(
          id: 'fe3',
          text: 'What is the final step before publishing a Flutter app?',
          type: QuestionType.identification,
          correctAnswer: 'Building a release APK or AAB',
        ),
        Question(
          id: 'fe4',
          text: 'Name the architecture pattern that separates UI from business logic.',
          type: QuestionType.identification,
          correctAnswer: 'MVVM',
        ),
        Question(
          id: 'fe5',
          text: 'List 3 emerging technologies shaping the future of mobile apps.',
          type: QuestionType.enumeration,
          correctAnswer: '5G',
          enumerationAnswers: ['5G', 'AI', 'Blockchain'],
        ),
      ],
    ),
  ];

  // ─── DBMS ─────────────────────────────────────────────────────────────────

  static final List<Assessment> _dbmsAssessments = [
    Assessment(
      id: 'dbms_prelims_quiz',
      subjectName: 'Database Management Systems 2',
      term: 'Prelims',
      type: 'Quiz',
      questions: [
        Question(
          id: 'dq1',
          text: 'What does SQL stand for?',
          type: QuestionType.multipleChoice,
          choices: [
            'Structured Query Language',
            'Simple Query Language',
            'Standard Query Logic',
            'System Query Layer',
          ],
          correctAnswer: 'Structured Query Language',
        ),
        Question(
          id: 'dq2',
          text: 'Which SQL clause is used to filter results?',
          type: QuestionType.multipleChoice,
          choices: ['ORDER BY', 'GROUP BY', 'WHERE', 'HAVING'],
          correctAnswer: 'WHERE',
        ),
        Question(
          id: 'dq3',
          text: 'What keyword is used to retrieve all columns?',
          type: QuestionType.identification,
          correctAnswer: 'SELECT *',
        ),
        Question(
          id: 'dq4',
          text: 'Name the constraint that ensures unique values in a column.',
          type: QuestionType.identification,
          correctAnswer: 'UNIQUE',
        ),
        Question(
          id: 'dq5',
          text: 'List 3 types of SQL JOIN operations.',
          type: QuestionType.enumeration,
          correctAnswer: 'INNER JOIN',
          enumerationAnswers: ['INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN'],
        ),
      ],
    ),
    Assessment(
      id: 'dbms_prelims_exam',
      subjectName: 'Database Management Systems 2',
      term: 'Prelims',
      type: 'Exam',
      questions: [
        Question(
          id: 'de1',
          text: 'Which normal form eliminates partial dependencies?',
          type: QuestionType.multipleChoice,
          choices: ['1NF', '2NF', '3NF', 'BCNF'],
          correctAnswer: '2NF',
        ),
        Question(
          id: 'de2',
          text: 'What is a foreign key?',
          type: QuestionType.multipleChoice,
          choices: [
            'A key from another country',
            'A column referencing a primary key in another table',
            'A unique identifier',
            'An encrypted key',
          ],
          correctAnswer: 'A column referencing a primary key in another table',
        ),
        Question(
          id: 'de3',
          text: 'What command is used to add a new record to a table?',
          type: QuestionType.identification,
          correctAnswer: 'INSERT INTO',
        ),
        Question(
          id: 'de4',
          text: 'Name the property that ensures database transactions are reliable.',
          type: QuestionType.identification,
          correctAnswer: 'ACID',
        ),
        Question(
          id: 'de5',
          text: 'List 3 types of database relationships.',
          type: QuestionType.enumeration,
          correctAnswer: 'One-to-One',
          enumerationAnswers: ['One-to-One', 'One-to-Many', 'Many-to-Many'],
        ),
      ],
    ),
    Assessment(
      id: 'dbms_midterms_quiz',
      subjectName: 'Database Management Systems 2',
      term: 'Midterms',
      type: 'Quiz',
      questions: [
        Question(
          id: 'dmq1',
          text: 'What is a stored procedure?',
          type: QuestionType.multipleChoice,
          choices: [
            'A saved query in the database',
            'A backup of the database',
            'A type of index',
            'A database user',
          ],
          correctAnswer: 'A saved query in the database',
        ),
        Question(
          id: 'dmq2',
          text: 'Which command removes a table and its data permanently?',
          type: QuestionType.multipleChoice,
          choices: ['DELETE', 'DROP', 'TRUNCATE', 'REMOVE'],
          correctAnswer: 'DROP',
        ),
        Question(
          id: 'dmq3',
          text: 'What does TRUNCATE do differently from DELETE?',
          type: QuestionType.identification,
          correctAnswer: 'Removes all rows without logging individual deletions',
        ),
        Question(
          id: 'dmq4',
          text: 'Name the SQL function used to count rows.',
          type: QuestionType.identification,
          correctAnswer: 'COUNT()',
        ),
        Question(
          id: 'dmq5',
          text: 'List 3 aggregate functions in SQL.',
          type: QuestionType.enumeration,
          correctAnswer: 'SUM',
          enumerationAnswers: ['SUM', 'AVG', 'MAX'],
        ),
      ],
    ),
    Assessment(
      id: 'dbms_midterms_exam',
      subjectName: 'Database Management Systems 2',
      term: 'Midterms',
      type: 'Exam',
      questions: [
        Question(
          id: 'dme1',
          text: 'What is a database view?',
          type: QuestionType.multipleChoice,
          choices: [
            'A physical table',
            'A virtual table based on a query',
            'An index',
            'A stored procedure',
          ],
          correctAnswer: 'A virtual table based on a query',
        ),
        Question(
          id: 'dme2',
          text: 'Which isolation level prevents dirty reads?',
          type: QuestionType.multipleChoice,
          choices: [
            'Read Uncommitted',
            'Read Committed',
            'Repeatable Read',
            'Serializable',
          ],
          correctAnswer: 'Read Committed',
        ),
        Question(
          id: 'dme3',
          text: 'What is an index used for in databases?',
          type: QuestionType.identification,
          correctAnswer: 'Speeding up query performance',
        ),
        Question(
          id: 'dme4',
          text: 'Name the command to modify existing records in a table.',
          type: QuestionType.identification,
          correctAnswer: 'UPDATE',
        ),
        Question(
          id: 'dme5',
          text: 'List 3 types of database indexes.',
          type: QuestionType.enumeration,
          correctAnswer: 'Clustered',
          enumerationAnswers: ['Clustered', 'Non-clustered', 'Composite'],
        ),
      ],
    ),
    Assessment(
      id: 'dbms_prefinals_quiz',
      subjectName: 'Database Management Systems 2',
      term: 'Pre-Finals',
      type: 'Quiz',
      questions: [
        Question(
          id: 'dpfq1',
          text: 'What is query optimization?',
          type: QuestionType.multipleChoice,
          choices: [
            'Writing shorter queries',
            'Improving query execution efficiency',
            'Using fewer tables',
            'Avoiding joins',
          ],
          correctAnswer: 'Improving query execution efficiency',
        ),
        Question(
          id: 'dpfq2',
          text: 'Which NoSQL database uses documents?',
          type: QuestionType.multipleChoice,
          choices: ['Redis', 'Cassandra', 'MongoDB', 'Neo4j'],
          correctAnswer: 'MongoDB',
        ),
        Question(
          id: 'dpfq3',
          text: 'What does NoSQL stand for?',
          type: QuestionType.identification,
          correctAnswer: 'Not Only SQL',
        ),
        Question(
          id: 'dpfq4',
          text: 'Name the technique used to distribute database load.',
          type: QuestionType.identification,
          correctAnswer: 'Sharding',
        ),
        Question(
          id: 'dpfq5',
          text: 'List 3 types of NoSQL databases.',
          type: QuestionType.enumeration,
          correctAnswer: 'Document',
          enumerationAnswers: ['Document', 'Key-Value', 'Graph'],
        ),
      ],
    ),
    Assessment(
      id: 'dbms_prefinals_exam',
      subjectName: 'Database Management Systems 2',
      term: 'Pre-Finals',
      type: 'Exam',
      questions: [
        Question(
          id: 'dpfe1',
          text: 'What is database replication?',
          type: QuestionType.multipleChoice,
          choices: [
            'Copying a table',
            'Duplicating data across multiple servers',
            'Backing up the database',
            'Merging two databases',
          ],
          correctAnswer: 'Duplicating data across multiple servers',
        ),
        Question(
          id: 'dpfe2',
          text: 'Which consistency model does MongoDB follow by default?',
          type: QuestionType.multipleChoice,
          choices: [
            'Strong Consistency',
            'Eventual Consistency',
            'ACID',
            'MVCC',
          ],
          correctAnswer: 'Eventual Consistency',
        ),
        Question(
          id: 'dpfe3',
          text: 'What is a transaction in a database?',
          type: QuestionType.identification,
          correctAnswer: 'A unit of work that is executed as a whole',
        ),
        Question(
          id: 'dpfe4',
          text: 'Name the CAP theorem property that ensures every request gets a response.',
          type: QuestionType.identification,
          correctAnswer: 'Availability',
        ),
        Question(
          id: 'dpfe5',
          text: 'List 3 benefits of database normalization.',
          type: QuestionType.enumeration,
          correctAnswer: 'Reduced redundancy',
          enumerationAnswers: [
            'Reduced redundancy',
            'Better data integrity',
            'Easier maintenance',
          ],
        ),
      ],
    ),
    Assessment(
      id: 'dbms_finals_quiz',
      subjectName: 'Database Management Systems 2',
      term: 'Finals',
      type: 'Quiz',
      questions: [
        Question(
          id: 'dfq1',
          text: 'What is database security primarily concerned with?',
          type: QuestionType.multipleChoice,
          choices: [
            'Increasing query speed',
            'Protecting data from unauthorized access',
            'Reducing storage costs',
            'Improving backup strategies',
          ],
          correctAnswer: 'Protecting data from unauthorized access',
        ),
        Question(
          id: 'dfq2',
          text: 'Which command grants access to a database user?',
          type: QuestionType.multipleChoice,
          choices: ['ALLOW', 'PERMIT', 'GRANT', 'ENABLE'],
          correctAnswer: 'GRANT',
        ),
        Question(
          id: 'dfq3',
          text: 'What is data warehousing?',
          type: QuestionType.identification,
          correctAnswer: 'Storing large volumes of historical data for analysis',
        ),
        Question(
          id: 'dfq4',
          text: 'Name the process of analyzing patterns in large datasets.',
          type: QuestionType.identification,
          correctAnswer: 'Data mining',
        ),
        Question(
          id: 'dfq5',
          text: 'List 3 components of a database management system.',
          type: QuestionType.enumeration,
          correctAnswer: 'Query processor',
          enumerationAnswers: [
            'Query processor',
            'Storage manager',
            'Transaction manager',
          ],
        ),
      ],
    ),
    Assessment(
      id: 'dbms_finals_exam',
      subjectName: 'Database Management Systems 2',
      term: 'Finals',
      type: 'Exam',
      questions: [
        Question(
          id: 'dfe1',
          text: 'What is OLAP used for?',
          type: QuestionType.multipleChoice,
          choices: [
            'Transaction processing',
            'Online analytical processing for reports',
            'Real-time data entry',
            'Database backups',
          ],
          correctAnswer: 'Online analytical processing for reports',
        ),
        Question(
          id: 'dfe2',
          text: 'Which technique improves performance by storing query results?',
          type: QuestionType.multipleChoice,
          choices: ['Indexing', 'Caching', 'Partitioning', 'Replication'],
          correctAnswer: 'Caching',
        ),
        Question(
          id: 'dfe3',
          text: 'What is the purpose of a database trigger?',
          type: QuestionType.identification,
          correctAnswer: 'To automatically execute actions on data changes',
        ),
        Question(
          id: 'dfe4',
          text: 'Name the SQL standard for stored procedures.',
          type: QuestionType.identification,
          correctAnswer: 'SQL/PSM',
        ),
        Question(
          id: 'dfe5',
          text: 'List 3 database backup strategies.',
          type: QuestionType.enumeration,
          correctAnswer: 'Full backup',
          enumerationAnswers: ['Full backup', 'Incremental backup', 'Differential backup'],
        ),
      ],
    ),
  ];

  // ─── IAS ──────────────────────────────────────────────────────────────────

  static final List<Assessment> _iasAssessments = [
    Assessment(
      id: 'ias_prelims_quiz',
      subjectName: 'Information Assurance Security 2',
      term: 'Prelims',
      type: 'Quiz',
      questions: [
        Question(
          id: 'iq1',
          text: 'What does CIA stand for in information security?',
          type: QuestionType.multipleChoice,
          choices: [
            'Central Intelligence Agency',
            'Confidentiality, Integrity, Availability',
            'Cyber Intrusion Analysis',
            'Code Integrity Assurance',
          ],
          correctAnswer: 'Confidentiality, Integrity, Availability',
        ),
        Question(
          id: 'iq2',
          text: 'Which type of attack involves intercepting communications?',
          type: QuestionType.multipleChoice,
          choices: [
            'Phishing',
            'Man-in-the-Middle',
            'SQL Injection',
            'Brute Force',
          ],
          correctAnswer: 'Man-in-the-Middle',
        ),
        Question(
          id: 'iq3',
          text: 'What is a firewall used for?',
          type: QuestionType.identification,
          correctAnswer: 'Monitoring and controlling network traffic',
        ),
        Question(
          id: 'iq4',
          text: 'Name the process of converting plaintext to unreadable format.',
          type: QuestionType.identification,
          correctAnswer: 'Encryption',
        ),
        Question(
          id: 'iq5',
          text: 'List 3 types of malware.',
          type: QuestionType.enumeration,
          correctAnswer: 'Virus',
          enumerationAnswers: ['Virus', 'Trojan', 'Ransomware'],
        ),
      ],
    ),
    Assessment(
      id: 'ias_prelims_exam',
      subjectName: 'Information Assurance Security 2',
      term: 'Prelims',
      type: 'Exam',
      questions: [
        Question(
          id: 'ie1',
          text: 'What is social engineering in cybersecurity?',
          type: QuestionType.multipleChoice,
          choices: [
            'Building social networks',
            'Manipulating people to reveal confidential information',
            'Engineering social media platforms',
            'Managing user accounts',
          ],
          correctAnswer: 'Manipulating people to reveal confidential information',
        ),
        Question(
          id: 'ie2',
          text: 'Which protocol ensures secure web communication?',
          type: QuestionType.multipleChoice,
          choices: ['HTTP', 'FTP', 'HTTPS', 'SMTP'],
          correctAnswer: 'HTTPS',
        ),
        Question(
          id: 'ie3',
          text: 'What is a zero-day vulnerability?',
          type: QuestionType.identification,
          correctAnswer: 'A flaw unknown to the vendor with no available patch',
        ),
        Question(
          id: 'ie4',
          text: 'Name the type of authentication using something you have.',
          type: QuestionType.identification,
          correctAnswer: 'Token-based authentication',
        ),
        Question(
          id: 'ie5',
          text: 'List 3 common network security threats.',
          type: QuestionType.enumeration,
          correctAnswer: 'DDoS',
          enumerationAnswers: ['DDoS', 'Phishing', 'SQL Injection'],
        ),
      ],
    ),
    Assessment(
      id: 'ias_midterms_quiz',
      subjectName: 'Information Assurance Security 2',
      term: 'Midterms',
      type: 'Quiz',
      questions: [
        Question(
          id: 'imq1',
          text: 'What is penetration testing?',
          type: QuestionType.multipleChoice,
          choices: [
            'Testing network speed',
            'Simulating attacks to find vulnerabilities',
            'Testing hardware durability',
            'Password testing',
          ],
          correctAnswer: 'Simulating attacks to find vulnerabilities',
        ),
        Question(
          id: 'imq2',
          text: 'Which encryption standard is widely used today?',
          type: QuestionType.multipleChoice,
          choices: ['DES', '3DES', 'AES', 'MD5'],
          correctAnswer: 'AES',
        ),
        Question(
          id: 'imq3',
          text: 'What does VPN stand for?',
          type: QuestionType.identification,
          correctAnswer: 'Virtual Private Network',
        ),
        Question(
          id: 'imq4',
          text: 'Name the attack that overwhelms a server with traffic.',
          type: QuestionType.identification,
          correctAnswer: 'DDoS (Distributed Denial of Service)',
        ),
        Question(
          id: 'imq5',
          text: 'List 3 principles of the CIA triad.',
          type: QuestionType.enumeration,
          correctAnswer: 'Confidentiality',
          enumerationAnswers: ['Confidentiality', 'Integrity', 'Availability'],
        ),
      ],
    ),
    Assessment(
      id: 'ias_midterms_exam',
      subjectName: 'Information Assurance Security 2',
      term: 'Midterms',
      type: 'Exam',
      questions: [
        Question(
          id: 'ime1',
          text: 'What is the purpose of a digital certificate?',
          type: QuestionType.multipleChoice,
          choices: [
            'To store passwords',
            'To verify the identity of a website or entity',
            'To encrypt files',
            'To block viruses',
          ],
          correctAnswer: 'To verify the identity of a website or entity',
        ),
        Question(
          id: 'ime2',
          text: 'Which hashing algorithm produces a 256-bit hash?',
          type: QuestionType.multipleChoice,
          choices: ['MD5', 'SHA-1', 'SHA-256', 'SHA-512'],
          correctAnswer: 'SHA-256',
        ),
        Question(
          id: 'ime3',
          text: 'What is public key infrastructure (PKI)?',
          type: QuestionType.identification,
          correctAnswer: 'A framework for managing digital certificates and encryption keys',
        ),
        Question(
          id: 'ime4',
          text: 'Name the practice of hiding secret messages within ordinary data.',
          type: QuestionType.identification,
          correctAnswer: 'Steganography',
        ),
        Question(
          id: 'ime5',
          text: 'List 3 cryptographic algorithms.',
          type: QuestionType.enumeration,
          correctAnswer: 'AES',
          enumerationAnswers: ['AES', 'RSA', 'SHA-256'],
        ),
      ],
    ),
    Assessment(
      id: 'ias_prefinals_quiz',
      subjectName: 'Information Assurance Security 2',
      term: 'Pre-Finals',
      type: 'Quiz',
      questions: [
        Question(
          id: 'ipfq1',
          text: 'What is an intrusion detection system (IDS)?',
          type: QuestionType.multipleChoice,
          choices: [
            'A system that blocks all traffic',
            'A system that monitors for suspicious activity',
            'A password manager',
            'A type of firewall',
          ],
          correctAnswer: 'A system that monitors for suspicious activity',
        ),
        Question(
          id: 'ipfq2',
          text: 'Which law governs data privacy in the Philippines?',
          type: QuestionType.multipleChoice,
          choices: [
            'RA 8792',
            'RA 10175',
            'RA 10173',
            'RA 9995',
          ],
          correctAnswer: 'RA 10173',
        ),
        Question(
          id: 'ipfq3',
          text: 'What is the purpose of a security audit?',
          type: QuestionType.identification,
          correctAnswer: 'To evaluate the effectiveness of security controls',
        ),
        Question(
          id: 'ipfq4',
          text: 'Name the process of recovering from a security incident.',
          type: QuestionType.identification,
          correctAnswer: 'Incident response',
        ),
        Question(
          id: 'ipfq5',
          text: 'List 3 types of access control models.',
          type: QuestionType.enumeration,
          correctAnswer: 'DAC',
          enumerationAnswers: ['DAC', 'MAC', 'RBAC'],
        ),
      ],
    ),
    Assessment(
      id: 'ias_prefinals_exam',
      subjectName: 'Information Assurance Security 2',
      term: 'Pre-Finals',
      type: 'Exam',
      questions: [
        Question(
          id: 'ipfe1',
          text: 'What is risk management in information security?',
          type: QuestionType.multipleChoice,
          choices: [
            'Eliminating all risks',
            'Identifying and mitigating security threats',
            'Purchasing insurance',
            'Auditing financial records',
          ],
          correctAnswer: 'Identifying and mitigating security threats',
        ),
        Question(
          id: 'ipfe2',
          text: 'Which framework is used for cybersecurity risk management?',
          type: QuestionType.multipleChoice,
          choices: ['ITIL', 'COBIT', 'NIST CSF', 'ISO 9001'],
          correctAnswer: 'NIST CSF',
        ),
        Question(
          id: 'ipfe3',
          text: 'What is business continuity planning (BCP)?',
          type: QuestionType.identification,
          correctAnswer:
              'A strategy to maintain operations during and after a disaster',
        ),
        Question(
          id: 'ipfe4',
          text: 'Name the document that defines acceptable use of organizational resources.',
          type: QuestionType.identification,
          correctAnswer: 'Acceptable Use Policy (AUP)',
        ),
        Question(
          id: 'ipfe5',
          text: 'List 3 components of a disaster recovery plan.',
          type: QuestionType.enumeration,
          correctAnswer: 'Backup strategy',
          enumerationAnswers: [
            'Backup strategy',
            'Recovery procedures',
            'Communication plan',
          ],
        ),
      ],
    ),
    Assessment(
      id: 'ias_finals_quiz',
      subjectName: 'Information Assurance Security 2',
      term: 'Finals',
      type: 'Quiz',
      questions: [
        Question(
          id: 'ifq1',
          text: 'What is ethical hacking?',
          type: QuestionType.multipleChoice,
          choices: [
            'Illegal hacking with good intentions',
            'Authorized testing of systems for vulnerabilities',
            'Hacking for profit',
            'Social engineering',
          ],
          correctAnswer: 'Authorized testing of systems for vulnerabilities',
        ),
        Question(
          id: 'ifq2',
          text: 'Which phase of ethical hacking involves gathering information?',
          type: QuestionType.multipleChoice,
          choices: [
            'Scanning',
            'Exploitation',
            'Reconnaissance',
            'Reporting',
          ],
          correctAnswer: 'Reconnaissance',
        ),
        Question(
          id: 'ifq3',
          text: 'What is a bug bounty program?',
          type: QuestionType.identification,
          correctAnswer:
              'A program that rewards researchers for finding security vulnerabilities',
        ),
        Question(
          id: 'ifq4',
          text: 'Name the tool commonly used for network scanning.',
          type: QuestionType.identification,
          correctAnswer: 'Nmap',
        ),
        Question(
          id: 'ifq5',
          text: 'List 3 phases of the ethical hacking process.',
          type: QuestionType.enumeration,
          correctAnswer: 'Reconnaissance',
          enumerationAnswers: ['Reconnaissance', 'Scanning', 'Exploitation'],
        ),
      ],
    ),
    Assessment(
      id: 'ias_finals_exam',
      subjectName: 'Information Assurance Security 2',
      term: 'Finals',
      type: 'Exam',
      questions: [
        Question(
          id: 'ife1',
          text: 'What is forensic investigation in cybersecurity?',
          type: QuestionType.multipleChoice,
          choices: [
            'Preventing cyber attacks',
            'Collecting and analyzing digital evidence',
            'Monitoring network traffic',
            'Testing software security',
          ],
          correctAnswer: 'Collecting and analyzing digital evidence',
        ),
        Question(
          id: 'ife2',
          text: 'Which law in the Philippines penalizes cybercrime?',
          type: QuestionType.multipleChoice,
          choices: ['RA 8792', 'RA 10175', 'RA 10173', 'RA 9995'],
          correctAnswer: 'RA 10175',
        ),
        Question(
          id: 'ife3',
          text: 'What is the chain of custody in digital forensics?',
          type: QuestionType.identification,
          correctAnswer:
              'Documentation of how evidence is collected, stored, and handled',
        ),
        Question(
          id: 'ife4',
          text: 'Name the international standard for information security management.',
          type: QuestionType.identification,
          correctAnswer: 'ISO 27001',
        ),
        Question(
          id: 'ife5',
          text: 'List 3 types of cyber attacks covered under RA 10175.',
          type: QuestionType.enumeration,
          correctAnswer: 'Hacking',
          enumerationAnswers: ['Hacking', 'Cybersex', 'Identity theft'],
        ),
      ],
    ),
  ];

  // ─── DEFAULT (fallback) ───────────────────────────────────────────────────

  static List<Assessment> _defaultAssessments(String subjectName) {
    return AssessmentData.terms.expand((term) {
      return ['Quiz', 'Exam'].map((type) {
        return Assessment(
          id: '${subjectName}_${term}_$type'.toLowerCase().replaceAll(' ', '_'),
          subjectName: subjectName,
          term: term,
          type: type,
          questions: [
            Question(
              id: 'default_q1',
              text: 'Sample question for $subjectName - $term $type',
              type: QuestionType.multipleChoice,
              choices: ['Option A', 'Option B', 'Option C', 'Option D'],
              correctAnswer: 'Option A',
            ),
          ],
        );
      }).toList();
    }).toList();
  }
}