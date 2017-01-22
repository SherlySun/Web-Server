
#include "server.hpp"
#include <utility>

namespace http {
namespace server {

server::server(const std::string& address, const std::string& port)
	: io_service_(),
	  acceptor_(io_service_),
	  socket_(io_service_)
  {
  	boost::asio::ip::tcp::resolver resolver(io_service_);
  	boost::asio::ip::tcp::endpoint endpoint = *resolver.resolve({address, port});
  	acceptor_.open(endpoint.protocol());
    acceptor_.set_option(boost::asio::ip::tcp::acceptor::reuse_address(true));
    acceptor_.bind(endpoint);
    acceptor_.listen();

    do_accept();
  }

void server::run()
{
	io_service_.run();
}

void server::do_accept()
{
  acceptor_.async_accept(socket_,
      [this](boost::system::error_code ec)
      {
        if (!ec) {
        	std::make_shared<connection>(std::move(socket_))->start();
        }

        do_accept();
      });
}

}
}