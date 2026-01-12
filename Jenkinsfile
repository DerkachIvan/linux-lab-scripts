pipeline{
    agent any

    environment {
        PACKAGE_NAME = 'count-files'
        PACKAGE_VERSION = sh(
            script: "git describe --tags --abbrev=0 || echo 1.0.0",
            returnStdout: true
        ).trim()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/DerkachIvan/linux-lab-scripts.git',
                        credentialsId: 'git-push-creds'
                    ]]
                ])
            }
        }


        /*stage('ShellCheck') {
            agent {
                docker {
                    image 'koalaman/shellcheck:stable'
                }
            }
            steps {
                sh '''
                    shellcheck count_files.sh || true
                '''
            }
        }*/


        stage('Test Script') {
            steps {
                sh "chmod +x count_files.sh"
                sh "bash -n count_files.sh"
                sh "./count_files.sh"
            }
        }

        stage('Build packages'){
            parallel{
                
                stage('Build RPM') {
                    agent{
                        docker{
                            image "fedora:latest"
                            args "-u root"
                        }
                    }
                    steps{
                        sh '''
                            dnf install -y rpm-build rpmdevtools
                            rpmdev-setuptree

                            mkdir -p ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp count_files.sh count_files.conf ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                            cd ~/rpmbuild/SOURCES/
                            
                            tar czvf ${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz ${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp ${WORKSPACE}/packaging/rpm/count-files.spec ~/rpmbuild/SPECS/
                            rpmbuild -ba \
                                --define "version ${PACKAGE_VERSION}" \
                                ~/rpmbuild/SPECS/count-files.spec

                            mkdir -p ${WORKSPACE}/artifacts
                            cp ~/rpmbuild/RPMS/noarch/*.rpm ${WORKSPACE}/

                            echo "=== RPM FILES ==="
                            ls -la ~/rpmbuild/RPMS/noarch || true
                            ls -la ${WORKSPACE}/
                        '''
                        stash name: 'rpm-artifact', includes: 'artifacts/*.rpm'
                    }
                }

                stage('Build DEB') {
                    agent{
                        docker{
                            image "ubuntu:latest"
                            args "-u root"
                        }
                    }
                    steps{
                        sh '''
                            apt-get update
                            apt-get install -y build-essential debhelper devscripts

                            mkdir -p build/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp count_files.sh count_files.conf build/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                            cp -r packaging/deb/debian build/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                            
                            cd build/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            dpkg-buildpackage -us -uc -b
                            
                            mkdir -p ${WORKSPACE}/artifacts
                            cp ../*.deb ${WORKSPACE}/
                            echo "=== DEB FILES ==="
                            ls -la ${WORKSPACE}/artifacts
                        '''
                        stash name: 'deb-artifact', includes: 'artifacts/*.deb'
                    }
                }
            }
        }

        stage('Test RPM Installation') {
            agent {
                docker {
                    image "oraclelinux:8"
                    args "-u root"
                }
            }
            steps {
                sh '''
                    rpm -ivh ${WORKSPACE}/${PACKAGE_NAME}-*.rpm
                    count_files
                    PACKAGE_INSTALLED=$(rpm -qa | grep ${PACKAGE_NAME} | head -n1)
                    rpm -e $PACKAGE_INSTALLED
                '''
            }
        }

        stage('Test DEB Installation') {
            agent {
                docker {
                    image "ubuntu:latest"
                    args "-u root"
                }
            }
            steps {
                sh '''
                    set -e
                    dpkg -i ${WORKSPACE}/${PACKAGE_NAME}_*.deb || apt-get install -f -y
                    count_files
                    apt-get remove -y ${PACKAGE_NAME} || true
                    echo "apt-get remove exit code $?"
                '''
            }
        }

        stage('Publish packages to Git') {
            agent any
            steps {
                withCredentials([string(credentialsId: 'git-push-creds', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        set -e

                        # Створюємо директорії для пакетів
                        mkdir -p repo/rpm repo/deb

                        # Копіюємо пакети, якщо вони є
                        cp artifacts/*.rpm repo/rpm/ 2>/dev/null || true
                        cp artifacts/*.deb repo/deb/ 2>/dev/null || true

                        # Налаштовуємо git
                        git config user.name "jenkins"
                        git config user.email "jenkins@localhost"

                        # Переключаємося на main і підтягнемо останні зміни
                        git fetch origin main:main
                        git checkout main

                        # Додаємо зміни
                        git add repo/

                        # Комітимо, якщо є зміни
                        if ! git diff-index --quiet HEAD --; then
                            git commit -m "Publish packages version ${PACKAGE_VERSION}"
                        else
                            echo "Nothing to commit"
                        fi

                        # Створюємо тег, якщо його ще немає
                        if git rev-parse "v${PACKAGE_VERSION}" >/dev/null 2>&1; then
                            echo "Tag v${PACKAGE_VERSION} already exists"
                        else
                            git tag -a v${PACKAGE_VERSION} -m "Release v${PACKAGE_VERSION}"
                        fi

                        # Пушимо main та тег
                        git push origin main
                        git push origin v${PACKAGE_VERSION} || echo "Tag already pushed"
                '''
                }
            }
        }

    }

    post {
        success {
            unstash 'rpm-artifact'
            unstash 'deb-artifact'
            sh '''
                echo "=== FILES ==="
                ls -la artifacts
            '''

            archiveArtifacts artifacts: 'artifacts/*.rpm'
            archiveArtifacts artifacts: 'artifacts/*.deb'
            echo 'Build completed successfully!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}